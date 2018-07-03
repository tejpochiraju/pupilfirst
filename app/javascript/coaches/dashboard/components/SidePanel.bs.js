// Generated by BUCKLESCRIPT VERSION 3.1.5, PLEASE EDIT WITH CARE
'use strict';

var React = require("react");
var ReasonReact = require("reason-react/src/ReasonReact.js");
var Coach$ReactTemplate = require("../types/Coach.bs.js");
var StartupsList$ReactTemplate = require("./StartupsList.bs.js");

((require("./SidePanel.scss")));

function str(prim) {
  return prim;
}

var component = ReasonReact.statelessComponent("SidePanel");

function make(coach, startups, selectedStartupId, selectStartupCB, clearStartupCB, _) {
  return /* record */[
          /* debugName */component[/* debugName */0],
          /* reactClassInternal */component[/* reactClassInternal */1],
          /* handedOffState */component[/* handedOffState */2],
          /* willReceiveProps */component[/* willReceiveProps */3],
          /* didMount */component[/* didMount */4],
          /* didUpdate */component[/* didUpdate */5],
          /* willUnmount */component[/* willUnmount */6],
          /* willUpdate */component[/* willUpdate */7],
          /* shouldUpdate */component[/* shouldUpdate */8],
          /* render */(function () {
              return React.createElement("div", {
                          className: "side-panel__container d-flex flex-column"
                        }, React.createElement("h3", {
                              className: "side-panel__coach-greeting py-3"
                            }, "Welcome " + Coach$ReactTemplate.name(coach)), ReasonReact.element(/* None */0, /* None */0, StartupsList$ReactTemplate.make(startups, selectedStartupId, selectStartupCB, clearStartupCB, /* array */[])));
            }),
          /* initialState */component[/* initialState */10],
          /* retainedProps */component[/* retainedProps */11],
          /* reducer */component[/* reducer */12],
          /* subscriptions */component[/* subscriptions */13],
          /* jsElementWrapped */component[/* jsElementWrapped */14]
        ];
}

exports.str = str;
exports.component = component;
exports.make = make;
/*  Not a pure module */
