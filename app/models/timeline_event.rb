# encoding: utf-8
# frozen_string_literal: true

class TimelineEvent < ApplicationRecord
  belongs_to :startup
  belongs_to :founder
  belongs_to :timeline_event_type
  belongs_to :target, optional: true

  has_one :karma_point, as: :source
  has_many :startup_feedback
  has_many :timeline_event_files, dependent: :destroy

  belongs_to :improved_timeline_event, class_name: 'TimelineEvent', optional: true
  has_one :improvement_of, class_name: 'TimelineEvent', foreign_key: 'improved_timeline_event_id'

  mount_uploader :image, TimelineImageUploader
  process_in_background :image

  serialize :links

  delegate :end_iteration?, :founder_event?, :title, to: :timeline_event_type

  MAX_DESCRIPTION_CHARACTERS = 500

  STATUS_PENDING = 'Pending'
  STATUS_NEEDS_IMPROVEMENT = 'Needs Improvement'
  STATUS_VERIFIED = 'Verified'
  STATUS_NOT_ACCEPTED = 'Not Accepted'

  def self.valid_statuses
    [STATUS_VERIFIED, STATUS_PENDING, STATUS_NEEDS_IMPROVEMENT, STATUS_NOT_ACCEPTED]
  end

  GRADE_GOOD = 'good'
  GRADE_GREAT = 'great'
  GRADE_WOW = 'wow'

  def self.valid_grades
    [GRADE_GOOD, GRADE_GREAT, GRADE_WOW]
  end

  normalize_attribute :grade

  validates :grade, inclusion: { in: valid_grades }, allow_nil: true
  validates :status, inclusion: { in: valid_statuses }
  validates :event_on, presence: true
  validates :description, presence: true
  validates :iteration, presence: true

  before_validation do
    self.status_updated_at = Time.zone.now if status_changed?
    self.status ||= STATUS_PENDING
  end

  accepts_nested_attributes_for :timeline_event_files, allow_destroy: true

  scope :end_of_iteration_events, -> { where(timeline_event_type: TimelineEventType.end_iteration) }
  scope :from_admitted_startups, -> { joins(:startup).merge(Startup.admitted) }
  scope :from_level_0_startups, -> { joins(:startup).merge(Startup.level_zero) }
  scope :not_dropped_out, -> { joins(:startup).merge(Startup.not_dropped_out) }
  scope :verified, -> { where(status: STATUS_VERIFIED) }
  scope :pending, -> { where(status: STATUS_PENDING) }
  scope :needs_improvement, -> { where(status: STATUS_NEEDS_IMPROVEMENT) }
  scope :not_accepted, -> { where(status: STATUS_NOT_ACCEPTED) }
  scope :verified_or_needs_improvement, -> { where(status: [STATUS_VERIFIED, STATUS_NEEDS_IMPROVEMENT]) }
  scope :has_image, -> { where.not(image: nil) }
  scope :from_approved_startups, -> { joins(:startup).merge(Startup.approved) }
  scope :showcase, -> { includes(:timeline_event_type, :startup).verified.from_approved_startups.not_private.order('timeline_events.event_on DESC') }
  scope :help_wanted, -> { where(timeline_event_type: TimelineEventType.help_wanted) }
  scope :not_private, -> { where(timeline_event_type: TimelineEventType.where.not(role: TimelineEventType::ROLE_FOUNDER)) }
  scope :not_improved, -> { joins(:target).where(improved_timeline_event_id: nil) }

  after_initialize :make_links_an_array

  def make_links_an_array
    self.links ||= []
  end

  before_save :ensure_links_is_an_array

  def ensure_links_is_an_array
    self.links = [] if links.nil?
  end

  before_validation :build_description

  def build_description
    return unless description.blank? && auto_populated

    self.description = case timeline_event_type.key
      when 'joined_svco'
        'We just registered our startup on SV.CO. Looking forward to an amazing learning experience!'
    end
  end

  after_commit do
    startup.update_stage! if timeline_event_type.stage_change?
  end

  attr_accessor :auto_populated

  # Accessors used by timeline builder form to create TimelineEventFile entries.
  # Should contain a hash: { identifier_key => uploaded_file, ... }
  attr_accessor :files

  # Writer used by timeline builder form to supply info about new / to-delete files.
  attr_writer :files_metadata

  def files_metadata
    @files_metadata || []
  end

  def files_metadata_json
    timeline_event_files.map do |file|
      {
        identifier: file.id,
        title: file.title,
        private: file.private?,
        persisted: true
      }
    end.to_json
  end

  # Return serialized links so that AA TimelineEvent#new/edit can use it.
  def serialized_links
    links.to_json
  end

  # Accept links in serialized form.
  def serialized_links=(links_string)
    self.links = JSON.parse(links_string).map(&:symbolize_keys)
  end

  after_save :update_timeline_event_files

  def update_timeline_event_files
    # Go through files metadata, and perform create / delete.
    files_metadata.each do |file_metadata|
      if file_metadata['persisted']
        # Delete persisted files if they've been flagged.
        if file_metadata['delete']
          timeline_event_files.find(file_metadata['identifier']).destroy!
        end
      else
        # Create non-persisted files.
        timeline_event_files.create!(
          title: file_metadata['title'],
          file: files[file_metadata['identifier']],
          private: file_metadata['private']
        )
      end
    end
  end

  def update_and_require_reverification(params)
    params[:status_updated_at] = Time.zone.now
    params[:status] = STATUS_PENDING
    update(params)
  end

  def verify!
    update!(status: STATUS_VERIFIED, status_updated_at: Time.zone.now)

    add_link_for_new_deck!
    add_link_for_new_wireframe!
    add_link_for_new_prototype!
    add_link_for_new_video!
  end

  def verified?
    status == STATUS_VERIFIED
  end

  def pending?
    status == STATUS_PENDING
  end

  def needs_improvement?
    status == STATUS_NEEDS_IMPROVEMENT
  end

  def not_accepted?
    status == STATUS_NOT_ACCEPTED
  end

  def to_be_graded?
    ([STATUS_VERIFIED, STATUS_NEEDS_IMPROVEMENT].include? status) && karma_point.blank?
  end

  def verified_or_needs_improvement?
    verified? || needs_improvement?
  end

  def founder_can_delete?
    !(verified_or_needs_improvement? || startup_feedback.present?)
  end

  def founder_can_modify?
    return false if end_iteration?
    !verified_or_needs_improvement?
  end

  def public_link?
    links.reject { |l| l[:private] }.present?
  end

  def points_for_grade
    minimum_point_for_target = target&.points_earnable
    return minimum_point_for_target if grade.blank?

    multiplier = {
      GRADE_GOOD => 1,
      GRADE_GREAT => 1.5,
      GRADE_WOW => 2
    }.with_indifferent_access[grade]

    minimum_point_for_target * multiplier
  end

  # A hidden timeline event is not displayed to user if user isn't logged in, or isn't the founder linked to event.
  def hidden_from?(viewer)
    return false unless timeline_event_type.founder_event?
    return true if viewer.blank?
    founder != viewer
  end

  def attachments_for_founder(founder)
    privileged = privileged_founder?(founder)
    attachments = []

    timeline_event_files.each do |file|
      next if file.private? && !privileged
      attachments << { file: file, title: file.title, private: file.private? }
    end

    links.each do |link|
      next if link[:private] && !privileged
      attachments << link
    end

    attachments
  end

  def founder_or_startup
    founder_event? ? founder : startup
  end

  def improved_event_candidates
    founder_or_startup.timeline_events
      .where(timeline_event_type: timeline_event_type)
      .where('created_at > ?', created_at)
      .where.not(id: id).order('event_on DESC')
  end

  def share_url
    Rails.application.routes.url_helpers.timeline_event_show_startup_url(
      id: startup.slug, event_title: title.parameterize, event_id: id
    )
  end

  def image_filename
    return if image.blank?
    image&.sanitized_file&.original_filename
  end

  def first_attachment_url
    @first_attachment_url ||= first_file_url || first_link_url
  end

  private

  def privileged_founder?(founder)
    founder.present? && startup.founders.include?(founder)
  end

  def add_link_for_new_deck!
    return unless timeline_event_type.new_deck?
    return if first_attachment_url.blank?
    startup.update!(presentation_link: first_attachment_url)
  end

  def add_link_for_new_wireframe!
    return unless timeline_event_type.new_wireframe?
    return if first_attachment_url.blank?
    startup.update!(wireframe_link: first_attachment_url)
  end

  def add_link_for_new_prototype!
    return unless timeline_event_type.new_prototype?
    return if first_attachment_url.blank?
    startup.update!(prototype_link: first_attachment_url)
  end

  def add_link_for_new_video!
    return unless timeline_event_type.new_video?
    return if first_attachment_url.blank?
    startup.update!(product_video_link: first_attachment_url)
  end

  def first_file_url
    first_file = timeline_event_files.first

    if first_file.present?
      Rails.application.routes.url_helpers.download_startup_timeline_event_timeline_event_file_url(
        startup, self, first_file
      )
    end
  end

  def first_link_url
    links.first.try(:[], :url)
  end
end
