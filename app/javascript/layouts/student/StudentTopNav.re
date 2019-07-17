[@bs.config {jsx: 3}];
[%bs.raw {|require("./StudentTopNav.css")|}];

let str = React.string;

open StudentTopNav__Types;

let headerLink = (key, link) =>
  <div
    key
    className="md:ml-5 text-sm font-semibold text-center cursor-default flex w-1/2 sm:w-1/3 md:w-auto justify-center border-r border-b md:border-0">
    <a
      className="no-underline bg-gray-100 md:bg-white text-black hover:text-primary-500 w-full p-4 md:p-2"
      href={link |> NavLink.url}>
      {link |> NavLink.title |> str}
    </a>
  </div>;

let logoutLink = authenticityToken =>
  <div
    key="Logout-button"
    className="md:ml-6 text-sm font-semibold cursor-default flex w-1/2 sm:w-1/3 md:w-auto justify-center border-r border-b md:border-0">
    <form className="button_to" method="post" action="/users/sign_out">
      <input name="_method" value="delete" type_="hidden" />
      <input
        name="authenticity_token"
        value=authenticityToken
        type_="hidden"
      />
      <div className="flex items-center justify-center">
        <button
          className="border border-primary-500 rounded px-2 py-1 text-primary-500 text-xs md:text-sm md:leading-normal m-4 md:m-0 no-underline font-semibold text-black"
          type_="submit"
          value="Submit">
          <FaIcon classes="far fa-power-off" />
          <span className="ml-2"> {"Logout" |> str} </span>
        </button>
      </div>
    </form>
  </div>;

let isMobile = () => Webapi.Dom.window |> Webapi.Dom.Window.innerWidth < 768;

let headerLinks = (links, authenticityToken) => {
  let (visibleLinks, dropdownLinks) =
    switch (links, isMobile()) {
    | (links, true) => (links, [])
    | ([l1, l2, l3, l4, l5, ...rest], false) => (
        [l1, l2, l3],
        [l4, l5, ...rest],
      )
    | (fourOrLessLinks, false) => (fourOrLessLinks, [])
    };

  switch (visibleLinks) {
  | visibleLinks =>
    (
      visibleLinks
      |> List.mapi((index, l) => headerLink(index |> string_of_int, l))
    )
    ->List.append([
        <StudentTopNav__DropDown links=dropdownLinks key="more-links" />,
      ])
    ->List.append([logoutLink(authenticityToken)])
    |> Array.of_list
    |> ReasonReact.array
  };
};

[@react.component]
let make = (~schoolName, ~logoUrl, ~links, ~authenticityToken) => {
  let (menuHidden, toggleMenuHidden) = React.useState(() => isMobile());

  React.useEffect(() => {
    let resizeCB = _ => toggleMenuHidden(_ => isMobile());
    Webapi.Dom.Window.asEventTarget(Webapi.Dom.window)
    |> Webapi.Dom.EventTarget.addEventListener("resize", resizeCB);
    None;
  });

  <div className="border-b">
    <div className="container mx-auto px-6 max-w-6xl">
      <nav className="flex justify-between items-center h-20">
        <div className="flex w-full items-center justify-between">
          <a className="max-w-xs" href="/">
            {
              switch (logoUrl) {
              | Some(url) =>
                <img
                  className="h-12 object-contain"
                  src=url
                  alt={"Logo of " ++ schoolName}
                />
              | None =>
                <span className="text-2xl text-black">
                  {schoolName |> str}
                </span>
              }
            }
          </a>
          {
            isMobile() ?
              <div onClick={_ => toggleMenuHidden(menuHidden => !menuHidden)}>
                <div
                  className={
                    "student-navbar__menu-btn w-8 h-8 text-center relative focus:outline-none rounded-full "
                    ++ (menuHidden ? "" : "open")
                  }>
                  <span className="student-navbar__menu-icon">
                    <span className="student-navbar__menu-icon-bar" />
                  </span>
                </div>
              </div> :
              React.null
          }
        </div>
        {
          !menuHidden && !isMobile() ?
            <div
              className="student-navbar__links-container flex justify-end items-center w-4/5 flex-no-wrap flex-shrink-0">
              {headerLinks(links, authenticityToken)}
            </div> :
            React.null
        }
      </nav>
    </div>
    {
      isMobile() && !menuHidden ?
        <div
          className="student-navbar__links-container flex flex-row border-t w-full flex-wrap shadow-lg">
          {headerLinks(links, authenticityToken)}
        </div> :
        React.null
    }
  </div>;
};