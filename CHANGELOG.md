# CHANGE LOG

## 0.4.4

* Fix the rootPath of recommendation and recommendation status for user's recommendation. Basically all data nodes relate to a recommendation should be stored in ":Devices:deviceUUID:pluginUUID:data" root.

## 0.4.3

* Add owner Id while creating a node

## 0.4.2

* Update with geiger_api: 0.8.0

## 0.4.1

* Update the sensor data node and the recommendation lifecycle

## 0.4.0

* Add custom description and urgency when updating node
* Modify the reading data from the node by adding the "key" to be more flexible

## 0.3.9

* Remove `-status` from the recommendation status node -> fix the problem of creating the status node

## 0.3.8

* Check the pre-prepared node to see if it already exist

## 0.3.7

* Add function to check if a recommendation node exists in local storage

## 0.3.6

* Add resolveRecommendation for completing the recommendation lifecycle

## 0.3.5

* Update with geiger_api: 0.7.9
* Add register and activate the plugin (required by the geiger_api: 0.7.9)

## 0.3.4

* Update with geiger_api: 0.7.8
* Update with flutter 3.0

## 0.3.3

* Update with geiger_api: 0.7.9

## 0.3.2

* save description into data node
* add static variables to request version of geiger api and geiger_localstorage

## 0.3.1

* Add description into sensor node model

## 0.3.0

* Add plugin description

## 0.2.9

* Update new structure of recommendation

## 0.2.8

* Update with geiger_api: 0.7.8 and geiger_localstorage: 0.6.48

## 0.2.7

* Update with geiger_api: 0.7.7
* Add sendDeviceRecommendation and sendUserRecommendation

## 0.2.6

* Update with geiger_api: 0.7.5
* Add some more settings based on plugin integration guide: <https://github.com/cyber-geiger/toolbox-communicationApi/wiki/Plugin-Integration>

## 0.2.5

* Update with geiger_api: 0.7.4 and geiger_localstorage: 0.6.46

## 0.2.4

* Correct version number

## 0.2.3

* change `GEIGERValue` to `GEIGERvalue`

## 0.2.2

* Add `GeigerApiConnector.version` to query the version of GeigerAPIConnector
* Replace app icon for example app

## 0.2.1

* Handle error in unCatchZone

## 0.2.0

* Add `updatePluginNode` method to write plugin information into the plugin node
* Update with geiger_api: 0.7.3 and geiger_localstorage: 0.6.42
* fix kotlin version to: 1.6.10

## 0.1.1

* Update with geiger_localstorage 0.6.38
* Add github action flow to automatically publish to pub.dev

## 0.1.0

* Update with geiger_api 0.7.2 and geiger_localstorage 0.6.37

## 0.0.2

* Update with GeigerAPI version 0.7.0 and Geiger LocalStorage version 0.6.31

## 0.0.1

* First version
