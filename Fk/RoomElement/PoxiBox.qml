// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import Fk.Pages

GraphicsBox {
  id: root

  title.text: Backend.callLuaFunction("PoxiPrompt", [poxi_type, card_data])

  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 70 + 700
  height: 64 + Math.min(cardView.contentHeight, 400) + 20

  signal cardSelected(int cid)
  signal cardsSelected(var ids)
  property var selected_ids: []
  property string poxi_type
  property var card_data

  ListModel {
    id: cardModel
  }

  ListView {
    id: cardView
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.bottomMargin: 20
    spacing: 20
    model: cardModel
    clip: true

    delegate: RowLayout {
      spacing: 15
      visible: areaCards.count > 0

      Rectangle {
        border.color: "#A6967A"
        radius: 5
        color: "transparent"
        width: 18
        height: 130
        Layout.alignment: Qt.AlignTop

        Text {
          color: "#E4D5A0"
          text: Backend.translate(areaName)
          anchors.fill: parent
          wrapMode: Text.WrapAnywhere
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          font.pixelSize: 15
        }
      }

      GridLayout {
        columns: 7
        Repeater {
          model: areaCards

          CardItem {
            cid: model.cid
            name: model.name || ""
            suit: model.suit || ""
            number: model.number || 0
            autoBack: false
            known: model.cid !== -1
            selectable: {
              return root.selected_ids.includes(model.cid) || JSON.parse(Backend.callLuaFunction(
                "PoxiFilter",
                [root.poxi_type, model.cid, root.selected_ids, root.card_data]
              ));
            }
            onSelectedChanged: {
              if (selected) {
                chosenInBox = true;
                root.selected_ids.push(cid);
              } else {
                chosenInBox = false;
                root.selected_ids.splice(root.selected_ids.indexOf(cid), 1);
              }
              root.selected_ids = root.selected_ids;
            }
          }
        }
      }
    }
  }

  MetroButton {
    anchors.bottom: parent.bottom
    text: Backend.translate("OK")
    enabled: {
      return JSON.parse(Backend.callLuaFunction(
        "PoxiFeasible",
        [root.poxi_type, root.selected_ids, root.card_data]
      ));
    }
    onClicked: root.cardsSelected(root.selected_ids)
  }

  onCardSelected: finished();

  function findAreaModel(name) {
    let ret;
    for (let i = 0; i < cardModel.count; i++) {
      let item = cardModel.get(i);
      if (item.areaName == name) {
        ret = item;
        break;
      }
    }
    if (!ret) {
      ret = {
        areaName: name,
        areaCards: [],
      }
      cardModel.append(ret);
      ret = findAreaModel(name);
    }
    return ret;
  }


  function addCustomCards(name, cards) {
    let area = findAreaModel(name).areaCards;
    if (cards instanceof Array) {
      for (let i = 0; i < cards.length; i++)
        area.append(cards[i]);
    } else {
      area.append(cards);
    }
  }
}
