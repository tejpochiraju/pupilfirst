ActiveAdmin.register Founder do
  include DisableIntercom

  controller do
    def scoped_collection
      super.includes :targets, :startup
    end

    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  menu label: 'Founders'

  scope :all
  scope :batched
  scope :missing_startups
  scope :inactive

  filter :startup_batch_id_eq, as: :select, collection: proc { Batch.all }, label: 'Batch'
  filter :email
  filter :name

  filter :ransack_tagged_with,
    as: :select,
    multiple: true,
    label: 'Tags',
    collection: -> { Founder.tag_counts_on(:tags).pluck(:name).sort }

  filter :roles_cont, as: :select, collection: Founder.valid_roles, label: 'Role'
  filter :college_name_contains
  filter :roll_number

  permit_params :name, :email, :remote_avatar_url, :avatar, :startup_id, :slug, :about, :slack_username, :born_on,
    :startup_admin, :communication_address, :identification_proof, :phone, :invitation_token, :college_id, :roll_number,
    :course, :semester, :year_of_graduation, :twitter_url, :linkedin_url, :personal_website_url, :blog_url,
    :facebook_url, :angel_co_url, :github_url, :behance_url, :gender, :skype_id, :exited, roles: [], tag_list: []

  batch_action :tag, form: proc { { tag: Founder.tag_counts_on(:tags).pluck(:name) } } do |ids, inputs|
    Founder.where(id: ids).each do |founder|
      founder.tag_list.add inputs[:tag]
      founder.save!
    end

    redirect_to collection_path, alert: 'Tag added!'
  end

  # Customize the index. Let's show only a small subset of the tons of fields.
  index do
    selectable_column
    column :name
    column :email

    column :product_name do |founder|
      if founder.startup.present?
        a href: admin_startup_path(founder.startup) do
          span do
            founder.startup.try(:product_name)
          end

          if founder.startup.name.present?
            span do
              " (#{founder.startup.name})"
            end
          end
        end
      end
    end

    column :karma_points do |founder|
      points = founder.karma_points.where('created_at > ?', Date.today.beginning_of_week).sum(:points)
      link_to points, admin_karma_points_path(q: { founder_id_eq: founder.id })
    end

    actions
  end

  csv do
    column :id
    column :email
    column :name

    column :product do |founder|
      founder.startup&.product_name
    end

    column :batch do |founder|
      founder.startup&.batch&.display_name
    end

    column :roles do |founder|
      founder.roles.join ', '
    end

    column :phone
    column :gender
    column :born_on
    column :communication_address
    column :about

    column :college do |founder|
      founder.college&.name
    end

    column :university do |founder|
      founder.university&.name
    end

    column :roll_number
    column :course
    column :semester
    column :year_of_graduation

    column :slack_username
    column(:skype_username, &:skype_id)

    column :startup_admin?
    column :slug

    column :resume_url
    column :linkedin_url
    column :twitter_url
    column :personal_website_url
    column :blog_url
    column :facebook_url
    column :angel_co_url
    column :github_url
    column :behance_url
  end

  member_action :remove_from_startup, method: :post do
    founder = Founder.friendly.find params[:id]
    founder.remove_from_startup!
    redirect_to action: :show
  end

  show do
    attributes_table do
      row :slug
      row :email
      row :name

      row :tags do |founder|
        linked_tags(founder.tags)
      end

      row :roles do |founder|
        founder.roles.map do |role|
          t("role.#{role}")
        end.join ', '
      end

      row :product_name do |founder|
        if founder.startup.present?
          a href: admin_startup_path(founder.startup) do
            span do
              founder.startup.try(:product_name)
            end

            if founder.startup.name.present?
              span do
                " (#{founder.startup.name})"
              end
            end
          end

          span class: 'wrap-with-paranthesis' do
            link_to 'Remove from Startup', remove_from_startup_admin_founder_path, method: :post, data: { confirm: 'Are you sure?' }
          end
        end
      end

      row :startup_admin
      row :about
      row :born_on
      row :slack_username
      row :slack_user_id
      row 'Skype Id' do
        founder.skype_id
      end

      row :resume_url do |founder|
        link_to(founder.resume_url, founder.resume_url) if founder.resume_url.present?
      end

      row :phone
      row :communication_address

      row :designation

      row :identification_proof do
        if founder.identification_proof.present?
          link_to 'Click here to open in new window', founder.identification_proof.url, target: '_blank'
        end
      end

      row :college
      row :university
      row :roll_number

      row :college_identification do
        if founder.college_identification.present?
          link_to founder.college_identification.url do
            image_tag founder.college_identification.thumb.url
          end
        end
      end

      row :course
      row :semester
      row :year_of_graduation
      row :exited
    end

    panel 'Social links' do
      attributes_table_for founder do
        row :twitter_url
        row :facebook_url
        row :linkedin_url
        row :personal_website_url
        row :blog_url
        row :angel_co_url
        row :github_url
        row :behance_url
      end
    end
  end

  action_item :feedback, only: :show, if: proc { Founder.friendly.find(params[:id]).startup.present? } do
    link_to(
      'Record New Feedback',
      new_admin_startup_feedback_path(
        startup_feedback: { startup_id: Founder.friendly.find(params[:id]).startup.id, reference_url: startup_url(Founder.friendly.find(params[:id]).startup) }
      )
    )
  end

  action_item :public_slack_messages, only: :show, if: proc { Founder.friendly.find(params[:id]).slack_username.present? } do
    link_to 'Public Slack Messages', admin_public_slack_messages_path(q: { founder_id_eq: params[:id] })
  end

  action_item :view_targets, only: :show do
    link_to 'View Targets', admin_targets_path(q: { assignee_type_eq: 'Founder', assignee_id_eq: founder.id })
  end

  form partial: 'admin/founders/form'
end
