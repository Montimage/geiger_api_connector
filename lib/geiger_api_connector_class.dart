import 'dart:convert';
import 'dart:developer';

import 'package:geiger_api/geiger_api.dart';
// ignore: depend_on_referenced_packages
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'package:geiger_api_connector/recommendation_node_model.dart';
import 'package:geiger_api_connector/utils.dart';

import 'plugin_event_listener.dart';
import 'sensor_node_model.dart';
import 'storage_event_listener.dart';

// enum DataUrgency { low, medium, high }

// String dataUrgencyToString(DataUrgency urg) {
//   switch (urg) {
//     case DataUrgency.low:
//       return 'low';
//     case DataUrgency.medium:
//       return 'medium';
//     case DataUrgency.high:
//       return 'high';
//     default:
//       return 'low';
//   }
// }

class GeigerApiConnector {
  static String version = '0.4.2';
  static String geigerAPIVersion = '0.8.0';
  static String geigerLocalStorageVersion = '0.8.0';

  GeigerApiConnector({
    required this.pluginId,
    required this.pluginName,
    this.exceptionHandler,
  });
  String pluginId; // Unique and assigned by GeigerToolbox
  String pluginName; // Name of the plugin
  GeigerApi? pluginApi;
  StorageController? storageController;
  Function? exceptionHandler;

  String? currentUserId; // will be retrieved from GeigerStorage
  String? currentDeviceId; // will be retrieved from GeigerStorage

  PluginEventListener? pluginListener; // listen to Plugin Event
  bool isPluginListenerRegistered = false;
  List<MessageType> handledEvents = [];

  StorageEventListener? storageListener; // Listen to Storage Change event
  bool isStorageListenerRegistered = false;

  /// Get an instance of GeigerApi, to be able to start working with GeigerToolbox
  Future<bool> connectToGeigerAPI(
      {String? pluginExecutor, String? masterExecutor}) async {
    log('Trying to connect to the GeigerApi');
    log('pluginExecutor: $pluginExecutor');
    log('masterExecutor: $masterExecutor');
    if (pluginApi != null) {
      log('Plugin $pluginId has been initialized');
      return true;
    } else {
      try {
        if (pluginId == GeigerApi.masterId) {
          flushGeigerApiCache();
          // MASTER PLUGIN
          // log('masterExecutor: ${GeigerApi.masterExecutor}');
          if (masterExecutor != null) {
            GeigerApi.masterExecutor = masterExecutor;
          }
          // log('masterExecutor(2): ${GeigerApi.masterExecutor}');
          pluginApi = await getGeigerApi(masterExecutor ?? '',
              GeigerApi.masterId, Declaration.doShareData);
          // log('masterExecutor(3): ${GeigerApi.masterExecutor}');
          if (pluginApi != null) {
            pluginApi!.zapState();
            log('MasterId: ${pluginApi.hashCode}');
            return true;
          } else {
            log('Failed to initialize the master plugin. Return null');
            await close();
            return false;
          }
        } else {
          // EXTERNAL PLUGIN
          // log('masterExecutor: ${GeigerApi.masterExecutor}');
          if (masterExecutor != null) {
            GeigerApi.masterExecutor = masterExecutor;
          }
          // log('masterExecutor(2): ${GeigerApi.masterExecutor}');
          pluginApi = await getGeigerApi(
              pluginExecutor ?? '', pluginId, Declaration.doShareData);
          if (pluginApi != null) {
            // pluginApi!.zapState();
            log('pluginApi: ${pluginApi.hashCode}');
            log('Going to regsiter the plugin $pluginId');
            await pluginApi!.registerPlugin();
            log('Going to activate the plugin $pluginId');
            await pluginApi!.activatePlugin();
            log('The Plugin $pluginId has been activated');
            return true;
          } else {
            log('Failed to initialize the master plugin. Return null');
            await close();
            return false;
          }
        }
      } catch (e, trace) {
        log('Failed to get the GeigerAPI');
        log(e.toString());
        await close();
        if (exceptionHandler != null) {
          exceptionHandler!(e, trace);
        }
        return false;
      }
    }
  }

  /// Close the geiger api properly
  Future<void> close() async {
    log('[close] Going to close the GeigerAPIConnector...');
    if (pluginApi != null) {
      if (storageController != null) {
        // Unregister all the listener
        if (storageListener != null) {
          log('[close] Going to deregister all the change listeners');
          try {
            await storageController!.deregisterChangeListener(storageListener!);
            log('[close] All the change listeners have been removed');
          } catch (e, trace) {
            log('[close] Failed to deregister the storage listener');
            log(e.toString());
            if (exceptionHandler != null) {
              exceptionHandler!(e, trace);
            }
          }
        }
        //close the storage controller
        // log('[close] Going to close the storage controller');
        // try {
        //   await storageController!.close();
        //   log('[close] The storage controller has been closed');
        // } catch (e) {
        //   log('[close] Failed to close the storage controller');
        //   log(e.toString());
        // }
        storageController = null;
        storageListener = null;
      }
      log('[close] Going to close the geiger api');
      try {
        await pluginApi!.zapState();
        await pluginApi!.close();
        pluginListener = null;
        pluginApi = null;
        log('[close] The GeigerAPI has been closed');
      } catch (e, trace) {
        log('[close] Failed to close the GeigerAPI');
        log(e.toString());
        if (exceptionHandler != null) {
          exceptionHandler!(e, trace);
        }
      }
    }
  }

  /// Get UUID of user or device
  Future getUUID(var key) async {
    var local = await storageController!.get(':Local');
    var temp = await local.getValue(key);
    return temp?.getValue('en');
  }

  /// Get an instance of GeigerStorage to read/write data
  Future<bool> connectToLocalStorage() async {
    log('Trying to connect to the GeigerStorage');
    if (storageController != null) {
      log('Plugin $pluginId has already connected to the GeigerStorage (${storageController.hashCode})');
      return await updateCurrentIds();
    } else {
      try {
        storageController = pluginApi!.storage;
        log('Connected to the GeigerStorage ${storageController.hashCode}');
        return await updateCurrentIds();
      } catch (e, trace) {
        log('Failed to connect to the GeigerStorage');
        await close();
        log(e.toString());
        if (exceptionHandler != null) {
          exceptionHandler!(e, trace);
        }
        return false;
      }
    }
  }

  /// Get all storage change event from Storage Listener
  List<EventChange> getAllStorageEvents() {
    return storageListener!.events;
  }

  /// Dump local storage value into terminal
  Future<String> dumpLocalStorage(String? path) async {
    final String storageStr = await storageController!.dump(path ?? ':');
    log('Storage Contents:');
    log(storageStr);
    return storageStr;
    // Node demoExample02 = NodeImpl(':Local:DemoExample', '');
    // await demoExample02.addOrUpdateValue(NodeValueImpl('GEIGERvalue', '100'));
    // log('Going to trigger some changes');
    // await storageController!.addOrUpdate(demoExample02);
  }

  /// Dynamically define the handler for each plugin event
  void addPluginEventhandler(MessageType type, Function handler) {
    if (pluginListener == null) {
      pluginListener = PluginEventListener('PluginListener-$pluginId');
      log('PluginListener: ${pluginListener.hashCode}');
    }
    handledEvents.add(type);
    pluginListener!.addPluginEventHandler(type, handler);
  }

  /// Register the storage listener
  Future<bool> registerStorageListener(
      {String? searchPath, Function? storageEventhandler}) async {
    if (isStorageListenerRegistered == true) {
      log('The storage listener ${pluginListener.hashCode} has been registered already!');
      return true;
    } else {
      if (storageListener == null) {
        // Create a storage listener
        storageListener = StorageEventListener(
            pluginId: pluginId, storageEventHandler: storageEventhandler);
        log('storageListener: ${storageListener.hashCode}');
      }
      try {
        SearchCriteria sc = SearchCriteria(searchPath: searchPath ?? ':');
        await storageController!.registerChangeListener(storageListener!, sc);
        log('StorageEventListener ${storageListener.hashCode} ($pluginId) has been registered');
        isStorageListenerRegistered = true;
        return true;
      } catch (e, trace) {
        log('Failed to register a storage listener');
        log(e.toString());
        if (exceptionHandler != null) {
          exceptionHandler!(e, trace);
        }
        return false;
      }
    }
  }

  // Register the plugin listener
  Future<bool> registerPluginListener() async {
    if (isPluginListenerRegistered == true) {
      log('The plugin listener ${pluginListener.hashCode} has been registered already!');
      return true;
    } else {
      if (pluginListener == null) {
        pluginListener = PluginEventListener('PluginListener-$pluginId');
        log('PluginListener: ${pluginListener.hashCode}');
      }
      try {
        // await pluginApi!
        //     .registerListener(handledEvents, pluginListener!); // This should be correct one
        pluginApi!.registerListener([MessageType.allEvents], pluginListener!);
        log('PluginListener ${pluginListener.hashCode} ($pluginId) has been registered and activated');
        isPluginListenerRegistered = true;
        return true;
      } catch (e, trace) {
        log('Failed to register a plugin listener');
        log(e.toString());
        if (exceptionHandler != null) {
          exceptionHandler!(e, trace);
        }
        return false;
      }
    }
  }

  /// Send a simple Plugin Event which contain only the message type to the GeigerToolbox
  Future<bool> sendPluginEventType(MessageType messageType) async {
    try {
      log('Trying to send a message type $messageType');
      // final GeigerUrl pluginURL = GeigerUrl.fromSpec('geiger://$pluginId');
      final Message request = Message(
        pluginId,
        GeigerApi.masterId,
        messageType,
        null,
      );
      await pluginApi!.sendMessage(request);
      log('A message type $messageType has been sent successfully');
      return true;
    } catch (e, trace) {
      log('Failed to send a message type $messageType');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  /// Return control - call to open an external plugin by its id
  Future<bool> callExternalPlugin(String externalPluginId) async {
    try {
      log('Trying to call a plugin: $externalPluginId');
      // final GeigerUrl pluginURL = GeigerUrl.fromSpec('geiger://$pluginId');
      final Message request = Message(
        GeigerApi.masterId,
        externalPluginId,
        MessageType.returningControl,
        null,
      );
      await pluginApi!.sendMessage(request);
      return true;
    } catch (e, trace) {
      log('Failed to call an external plugin: $externalPluginId');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  /// Send a plugin event with payload
  Future<bool> sendPluginEventWithPayload(
      MessageType messageType, String payload) async {
    try {
      log('Trying to send a message type $messageType');
      // final GeigerUrl pluginURL = GeigerUrl.fromSpec('geiger://$pluginId');
      final Message request = Message(
        pluginId,
        GeigerApi.masterId,
        messageType,
        null,
        utf8.encode(payload),
      );
      await pluginApi!.sendMessage(request);
      log('A message type $messageType has been sent successfully');
      return true;
    } catch (e, trace) {
      log('Failed to send a message type $messageType');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  /// Show some statistics of Listener
  String getPluginListenerStats() {
    return pluginListener.toString();
  }

  /// Get the list of all plugin events
  List<Message> getAllPluginEvents() {
    return pluginListener!.getAllPluginEvents();
  }

  String showAllPluginEvents() {
    String ret = '';
    final List<Message> allEvents = pluginListener!.getAllPluginEvents();
    if (allEvents.isEmpty) return '<There is not any plugin event>';
    ret = 'Total number of Plugin events: ${allEvents.length}\n\n';
    for (var i = 0; i < allEvents.length; i++) {
      ret += allEvents[i].toString();
      log('\n Message: $ret');
      if (allEvents[i].payload.isNotEmpty) {
        log('\n Going to show payload');
        try {
          String payloadText = utf8.decode(allEvents[i].payload);
          // log('\nPayload: $payloadText');
          ret += '\nPayload:\n$payloadText';
        } catch (e) {
          log('Failed to decode payload: ${e.toString()}');
        }
      }
      ret += '\n-------\n';
    }
    return ret;
  }

  String showAllStorageEvents() {
    String ret = '';
    final List<EventChange> allEvents = storageListener!.getAllStorageEvents();
    if (allEvents.isEmpty) return '<There is not any storage event>';
    ret = 'Total number of storage events: ${allEvents.length}\n\n';
    for (var i = 0; i < allEvents.length; i++) {
      ret += allEvents[i].toString();
      ret += '\n-------\n';
    }
    return ret;
  }

  /// Send some device sensor data to GeigerToolbox
  Future<bool> sendDeviceSensorData(String sensorId, String value,
      {String? description, String? urgency}) async {
    String nodePath =
        ':Devices:$currentDeviceId:$pluginId:data:metrics:$sensorId';
    try {
      Node node = await storageController!.get(nodePath);
      node.addOrUpdateValue(NodeValueImpl('GEIGERvalue', value));
      if (description != null) {
        node.addOrUpdateValue(NodeValueImpl('description', description));
      }
      if (urgency != null) {
        node.addOrUpdateValue(NodeValueImpl('urgency', urgency));
      }

      // if (recommendationId != null) {
      //   node.addOrUpdateValue(
      //     NodeValueImpl('currentRecommendationId', recommendationId),
      //   );
      // }
      await storageController!.addOrUpdate(node);
      log('Updated node: ');
      log(node.toString());
      return true;
    } catch (e, trace) {
      log('Failed to get node $nodePath');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  /// Send some user sensor data to GeigerToolbox
  Future<bool> sendUserSensorData(String sensorId, String value,
      {String? description, String? urgency}) async {
    String nodePath = ':Users:$currentUserId:$pluginId:data:metrics:$sensorId';
    try {
      Node node = await storageController!.get(nodePath);
      node.addOrUpdateValue(NodeValueImpl('GEIGERvalue', value));
      if (description != null) {
        node.addOrUpdateValue(NodeValueImpl('description', description));
      }
      if (urgency != null) {
        node.addOrUpdateValue(NodeValueImpl('urgency', urgency));
      }

      // if (recommendationId != null) {
      //   node.addOrUpdateValue(
      //     NodeValueImpl('currentRecommendationId', recommendationId),
      //   );
      // }
      await storageController!.addOrUpdate(node);
      log('Updated node: ');
      log(node.toString());
      return true;
    } catch (e, trace) {
      log('Failed to send a data node $nodePath');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  /// Update a node value
  Future<bool> updateNodeValue(
      String nodePath, String key, String value) async {
    try {
      Node node = await storageController!.get(nodePath);
      node.addOrUpdateValue(
        NodeValueImpl(key, value),
      );
      await storageController!.addOrUpdate(node);
      log('Updated node: ');
      log(node.toString());
      return true;
    } catch (e, trace) {
      log('Failed to update node $nodePath');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  /// Prepare a root node with given path
  Future<bool> prepareRoot(List<String> rootPath, String? owner) async {
    bool checkNode = await isNodeExist(':${rootPath.join(':')}');
    if (checkNode) {
      log('Root path has already existed $rootPath');
      return true;
    }
    String currentRoot = '';
    int currentIndex = 0;
    while (currentIndex < rootPath.length) {
      try {
        await storageController!.addOrUpdate(
          NodeImpl(rootPath[currentIndex], owner ?? '',
              currentRoot == '' ? ':' : currentRoot, Visibility.white),
        );
        currentRoot = '$currentRoot:${rootPath[currentIndex]}';
        currentIndex++;
      } catch (e, trace) {
        log('Failed to prepare the path: $currentRoot:${rootPath[currentIndex]}');
        log(e.toString());
        if (exceptionHandler != null) {
          exceptionHandler!(e, trace);
        }
        return false;
      }
    }
    Node testNode = await storageController!.get(currentRoot);
    log('Root: ${testNode.toString()}');
    return true;
  }

  /// Verify if a node exist
  Future<bool> isNodeExist(String nodePath) async {
    try {
      await storageController!.get(nodePath);
      return true;
    } catch (e) {
      // log(e.toString());
      return false;
    }
  }

  /// Send a data node which include creating a new node and write the data
  Future<bool> sendDataNode(String nodeId, String nodePath, List<String> keys,
      List<String> values, String? owner) async {
    if (keys.length != values.length) {
      log('The size of keys and values must be the same');
      return false;
    }
    try {
      Node node = NodeImpl(nodeId, owner ?? '', nodePath, Visibility.white);
      for (var i = 0; i < keys.length; i++) {
        await node.addValue(NodeValueImpl(keys[i], values[i]));
      }
      // node.visibility = Visibility.white;
      await storageController!.addOrUpdate(node);
      return true;
    } catch (e, trace) {
      log('Failed to send a data node: $nodePath');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  Future<bool> isRecommendationExist(String rootType, String sensorId) async {
    String dataNodePath =
        ':$rootType:${rootType == 'Users' ? '$currentUserId' : '$currentDeviceId'}:$pluginId:data:metrics:$sensorId';
    String? currentRecommendationId =
        await _readValueNode(dataNodePath, 'currentRecommendationId');
    if (currentRecommendationId != null && currentRecommendationId.isNotEmpty) {
      String recPath =
          ':$rootType:${rootType == 'Users' ? '$currentUserId' : '$currentDeviceId'}:$pluginId:data:recommendations:$currentRecommendationId';
      return await isNodeExist(recPath);
    }
    return false;
  }

  /// Add a new recommendation
  /// - Check if the data node has already a recommendation -> not send a new one
  /// - if the data node does not have a recommendation, or the currentRecommendationId = '', then send a new once
  Future<bool> sendRecommendation(
      String rootType, RecommendationNodeModel recommendationNodeModel) async {
    String dataRoot =
        ':$rootType:${rootType == 'Users' ? '$currentUserId' : '$currentDeviceId'}:$pluginId:data';
    String dataNodeRootPath =
        '$dataRoot:metrics:${recommendationNodeModel.sensorId}';
    String? currentRecommendationId =
        await _readValueNode(dataNodeRootPath, 'currentRecommendationId');
    if (currentRecommendationId != null && currentRecommendationId.isNotEmpty) {
      log('A recommendation has been sent and unresolved $currentRecommendationId. Do not send a new once');
      return true;
    }
    log('Going to send a new recommendation');
    String recommendationRootPath = '$dataRoot:recommendations';
    String recommendationId = getUniqueId();
    String createdDate = DateTime.now().toIso8601String();
    try {
      Node node = NodeImpl(recommendationId, '', recommendationRootPath);
      await node.addOrUpdateValue(
        NodeValueImpl(
            'short', '${recommendationNodeModel.short} - $createdDate'),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('long', recommendationNodeModel.long),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('Action', recommendationNodeModel.action),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('relatedThreatsWeights',
            recommendationNodeModel.relatedThreatsWeights),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('costs', recommendationNodeModel.costs),
      );
      await node.addOrUpdateValue(
        NodeValueImpl(
            'RecommendationType', recommendationNodeModel.recommendationType),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('pluginId', pluginId),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('pluginName', pluginName),
      );

      await node.addOrUpdateValue(
        NodeValueImpl('createdDate', createdDate),
      );

      log('A recommendation node has been created');
      log(node.toString());
      try {
        await storageController!.addOrUpdate(node);
        log('After adding a recommendation node $recommendationId');
        updateNodeValue(
            dataNodeRootPath, 'currentRecommendationId', recommendationId);
        return true;
      } catch (e2, trace2) {
        log('Failed to update Storage');
        log(e2.toString());
        if (exceptionHandler != null) {
          exceptionHandler!(e2, trace2);
        }
        return false;
      }
    } catch (e, trace) {
      log('Failed to add a recommendation node $recommendationId');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  /// Resolve a recommendation
  /// - Get the sensor node with
  /// - Update the currentRecommendationId of the sensor node to be empty
  /// - Create a recommendation status node
  Future<bool> resolveRecommendation(
      String rootType, String sensorId, String geigerValue) async {
    String rootPath =
        ':$rootType:${rootType == 'Users' ? currentUserId : currentDeviceId}:$pluginId:data:metrics';
    String? currentRecommendationId =
        await _readValueNode('$rootPath:$sensorId', 'currentRecommendationId');
    if (currentRecommendationId == null || currentRecommendationId.isEmpty) {
      log('Cannot find the recommendation for the sensor data: $sensorId');
      return false;
    }

    log('Before adding a recommendation status node $currentRecommendationId');
    try {
      // bool isRootExist = await isNodeExist(rootPath);
      // if (!isRootExist) {
      //   log('Root $rootPath is not exist');
      //   return false;
      // }

      Node node = NodeImpl(currentRecommendationId, '', rootPath);
      await node.addOrUpdateValue(
        NodeValueImpl(
            'name', 'Recommendation status of $currentRecommendationId'),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('description',
            'Reflects the status of the recommendation with the indicated ID. geigerValue 0=resolved, 1=active'),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('minValue', '0'),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('maxValue', '1'),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('valueType', 'int'),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('flag', '0'),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('urgency', 'low'),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('threatsImpact', ''),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('geigerValue', geigerValue),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('recommendationId', currentRecommendationId),
      );
      log('A recommendation status node has been created');
      log(node.toString());
      try {
        log('Going to add a recommendation status node $currentRecommendationId');
        await storageController!.addOrUpdate(node);
        log('After adding a recommendation status node $currentRecommendationId');
        log('Going to update the sensor node');
        try {
          await updateNodeValue(
              '$rootPath:$sensorId', 'currentRecommendationId', '');
          return true;
        } catch (e3) {
          log('Failed to update the sensor node');
          log(
            e3.toString(),
          );
          return false;
        }
      } catch (e2, trace2) {
        log('Failed to update Storage');
        log(e2.toString());
        if (exceptionHandler != null) {
          exceptionHandler!(e2, trace2);
        }
        return false;
      }
    } catch (e, trace) {
      log('Failed to add a recommendation status node $currentRecommendationId');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  // Future<bool> resolveDeviceRecommendation(SensorDataModel sensorDataModel,
  //     String recommendationId, String geigerValue) async {
  //   return await _resolveRecommendation(
  //       sensorDataModel, 'Devices', recommendationId, geigerValue);
  // }

  // Future<bool> resolveUserRecommendation(SensorDataModel sensorDataModel,
  //     String recommendationId, String geigerValue) async {
  //   return await _resolveRecommendation(
  //       sensorDataModel, 'Users', recommendationId, geigerValue);
  // }

  // Future<bool> _resolveRecommendation(SensorDataModel sensorDataModel,
  //     String rootType, String recommendationId, String geigerValue) async {
  //   String rootPath =
  //       ':$rootType:${rootType == 'Users' ? currentUserId : currentDeviceId}:$pluginId:data:metrics';
  //   String nodeId = '$recommendationId-status';
  //   log('Before adding a sensor node $nodeId');
  //   try {
  //     Node node = NodeImpl(nodeId, '', rootPath);
  //     await node.addOrUpdateValue(
  //       NodeValueImpl('name', sensorDataModel.name),
  //     );
  //     await node.addOrUpdateValue(
  //       NodeValueImpl('description', sensorDataModel.description),
  //     );
  //     await node.addOrUpdateValue(
  //       NodeValueImpl('minValue', sensorDataModel.minValue),
  //     );
  //     await node.addOrUpdateValue(
  //       NodeValueImpl('maxValue', sensorDataModel.maxValue),
  //     );
  //     await node.addOrUpdateValue(
  //       NodeValueImpl('valueType', sensorDataModel.valueType),
  //     );
  //     await node.addOrUpdateValue(
  //       NodeValueImpl('flag', sensorDataModel.flag),
  //     );
  //     await node.addOrUpdateValue(
  //       NodeValueImpl('threatsImpact', sensorDataModel.threatsImpact),
  //     );
  //     await node.addOrUpdateValue(
  //       NodeValueImpl('recommendationId', recommendationId),
  //     );
  //     await node.addOrUpdateValue(
  //       NodeValueImpl('geigerValue', geigerValue),
  //     );
  //     log('A node has been created');
  //     log(node.toString());
  //     try {
  //       await storageController!.addOrUpdate(node);
  //       log('After adding a sensor node $nodeId');
  //       return true;
  //     } catch (e2, trace2) {
  //       log('Failed to update Storage');
  //       log(e2.toString());
  //       if (exceptionHandler != null) {
  //         exceptionHandler!(e2, trace2);
  //       }
  //       return false;
  //     }
  //   } catch (e, trace) {
  //     log('Failed to add a sensor node $nodeId');
  //     log(e.toString());
  //     if (exceptionHandler != null) {
  //       exceptionHandler!(e, trace);
  //     }
  //     return false;
  //   }
  // }

  Future<bool> addUserSensorNode(SensorDataModel sensorDataModel) async {
    return await _addSensorNode(sensorDataModel, 'Users');
  }

  Future<bool> addDeviceSensorNode(SensorDataModel sensorDataModel) async {
    return await _addSensorNode(sensorDataModel, 'Devices');
  }

  Future<bool> _addSensorNode(
      SensorDataModel sensorDataModel, String rootType) async {
    String rootPath =
        ':$rootType:${rootType == 'Users' ? currentUserId : currentDeviceId}:$pluginId:data:metrics';
    log('Before adding a sensor node ${sensorDataModel.sensorId}');
    try {
      bool checkNode =
          await isNodeExist('$rootPath:${sensorDataModel.sensorId}');
      if (checkNode) {
        log('Node ${sensorDataModel.sensorId} has already existed');
        return true;
      }

      Node node = NodeImpl(sensorDataModel.sensorId, '', rootPath);
      await node.addOrUpdateValue(
        NodeValueImpl('name', sensorDataModel.name),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('description', sensorDataModel.description),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('minValue', sensorDataModel.minValue),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('maxValue', sensorDataModel.maxValue),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('valueType', sensorDataModel.valueType),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('flag', sensorDataModel.flag),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('urgency', sensorDataModel.urgency),
      );
      await node.addOrUpdateValue(
        NodeValueImpl('threatsImpact', sensorDataModel.threatsImpact),
      );
      log('A node has been created');
      log(node.toString());
      try {
        await storageController!.addOrUpdate(node);
        log('After adding a sensor node ${sensorDataModel.sensorId}');
        return true;
      } catch (e2, trace2) {
        log('Failed to update Storage');
        log(e2.toString());
        if (exceptionHandler != null) {
          exceptionHandler!(e2, trace2);
        }
        return false;
      }
    } catch (e, trace) {
      log('Failed to add a sensor node ${sensorDataModel.sensorId}');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  /// Read a value of user sensor
  Future<String?> readUserSensorData(
      String pluginId, String sensorId, String key) async {
    return await _readValueNode(
        ':Users:$currentUserId:$pluginId:data:metrics:$sensorId', key);
  }

  /// Read a value of device sensor
  Future<String?> readDeviceSensorData(
      String pluginId, String sensorId, String key) async {
    return await _readValueNode(
        ':Devices:$currentDeviceId:$pluginId:data:metrics:$sensorId', key);
  }

  Future<String?> _readValueNode(String nodePath, String key) async {
    log('Going to get value of node at $nodePath');
    try {
      Node node = await storageController!.get(nodePath);
      var temp = await node.getValue(key);
      return temp?.getValue('en');
    } catch (e, trace) {
      log('Failed to get value of node at $nodePath');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return null;
    }
  }

  Future<bool> updateCurrentIds() async {
    log('Going to update the userId and the deviceId');
    try {
      currentUserId = await getUUID('currentUser');
      currentDeviceId = await getUUID('currentDevice');
      log('currentUserId: $currentUserId');
      log('currentDeviceId: $currentDeviceId');
      return true;
    } catch (e, trace) {
      log('Failed to update the userId and the deviceId');
      log(e.toString());
      if (exceptionHandler != null) {
        exceptionHandler!(e, trace);
      }
      return false;
    }
  }

  /// Update the information of the external plugin
  Future<bool> updatePluginInfo(
      String pluginId, String companyName, String description) async {
    // Prepare the plugin node
    bool ret = await prepareRoot([
      'Devices',
      currentDeviceId!,
    ], '');
    if (ret == false) {
      log('Failed to prepare the plugin node');
      return false;
    }
    // Write plugin info
    ret = await sendDataNode(
        pluginId,
        ':Devices:${currentDeviceId!}',
        ['name', 'company_name', 'description'],
        [pluginName, companyName, description],
        null);
    if (ret == false) {
      log('Failed to store plugin information');
      return false;
    }
    return true;
  }

  /// Open the Geiger Toolbox
  Future<bool> openGeigerToolbox() async {
    return await sendPluginEventType(MessageType.returningControl);
  }
}
