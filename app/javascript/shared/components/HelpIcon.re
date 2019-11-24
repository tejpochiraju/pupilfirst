[@bs.config {jsx: 3}];

let str = React.string;

[%bs.raw {|require("./HelpIcon.css")|}];

let onWindowClick = (helpVisible, setHelpVisible, _event) =>
  if (helpVisible) {
    setHelpVisible(_ => false);
  } else {
    ();
  };

let toggleHelp = (setHelpVisible, event) => {
  event |> ReactEvent.Mouse.stopPropagation;
  setHelpVisible(helpVisible => !helpVisible);
};

type alignment =
  | AlignLeft
  | AlignRight
  | AlignCenter;

let alignmentClass = position =>
  switch (position) {
  | AlignLeft => " left-0"
  | AlignRight => " right-0"
  | AlignCenter => " help-icon__help-container--center"
  };

[@react.component]
let make = (~className="", ~link=?, ~alignment=AlignCenter, ~children) => {
  let (helpVisible, setHelpVisible) = React.useState(() => false);

  React.useEffect1(
    () => {
      let curriedFunction = onWindowClick(helpVisible, setHelpVisible);
      let window = Webapi.Dom.window;

      let removeEventListener = () =>
        Webapi.Dom.Window.removeEventListener(
          "click",
          curriedFunction,
          window,
        );

      if (helpVisible) {
        Webapi.Dom.Window.addEventListener("click", curriedFunction, window);
        Some(removeEventListener);
      } else {
        removeEventListener();
        None;
      };
    },
    [|helpVisible|],
  );

  <div
    className={"inline-block relative " ++ className}
    onClick={toggleHelp(setHelpVisible)}>
    <FaIcon
      classes="fas fa-question-circle hover:text-gray-700 cursor-pointer"
    />
    {helpVisible
       ? <div
           className={
             "help-icon__help-container overflow-y-auto mt-1 border border-gray-900 absolute z-50 p-2 rounded-lg bg-gray-900 text-white max-w-xs text-center"
             ++ (alignment |> alignmentClass)
           }>
           children
           {link
            |> OptionUtils.map(link =>
                 <a
                   href=link
                   target="_blank"
                   className="block mt-1 text-blue-300 hover:text-blue:200">
                   <FaIcon classes="fas fa-external-link-square-alt" />
                   <span className="ml-1"> {"Read more" |> str} </span>
                 </a>
               )
            |> OptionUtils.default(React.null)}
         </div>
       : React.null}
  </div>;
};

module Jsx2 = {
  let make = (~className=?, ~link=?, ~alignment=?, children) =>
    ReasonReactCompat.wrapReactForReasonReact(
      make,
      makeProps(
        ~className?,
        ~link?,
        ~alignment?,
        ~children=children |> React.array,
        (),
      ),
      children,
    );
};