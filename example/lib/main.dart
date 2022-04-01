import 'dart:io';
import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geiger_api_connector/geiger_api_connector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  if (Platform.isWindows) {
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(417, 732);
      win.minSize = initialSize;
      win.size = initialSize;
      win.alignment = Alignment.center;
      win.title = "Custom window with Flutter";
      win.show();
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const String montimagePluginId = 'geiger-api-example-external-plugin-id';

class _MyHomePageState extends State<MyHomePage> {
  List<Message> events = [];
  String userData = '';
  String deviceData = '';
  bool isInProcessing = false;
  bool isMasterStarted = false;
  bool isExternalPluginStarted = false;
  String? masterOutput;
  String? pluginOutput;

  GeigerApiConnector masterApiConnector =
      GeigerApiConnector(pluginId: GeigerApi.masterId);
  GeigerApiConnector pluginApiConnector =
      GeigerApiConnector(pluginId: montimagePluginId);
  SensorDataModel userNodeDataModel = SensorDataModel(
      sensorId: 'mi-cyberrange-score-sensor-id',
      name: 'MI Cyberrange Score',
      minValue: '0',
      maxValue: '100',
      valueType: 'double',
      flag: '1',
      threatsImpact:
          '80efffaf-98a1-4e0a-8f5e-gr89388352ph,High;80efffaf-98a1-4e0a-8f5e-gr89388354sp,Hight;80efffaf-98a1-4e0a-8f5e-th89388365it,Hight;80efffaf-98a1-4e0a-8f5e-gr89388350ma,Medium;80efffaf-98a1-4e0a-8f5e-gr89388356db,Medium');
  SensorDataModel deviceNodeDataModel = SensorDataModel(
      sensorId: 'mi-ksp-scanner-is-rooted-device',
      name: 'Is device rooted',
      minValue: 'false',
      maxValue: 'true',
      valueType: 'boolean',
      flag: '0',
      threatsImpact:
          '80efffaf-98a1-4e0a-8f5e-gr89388352ph,High;80efffaf-98a1-4e0a-8f5e-gr89388354sp,Hight;80efffaf-98a1-4e0a-8f5e-th89388365it,Hight;80efffaf-98a1-4e0a-8f5e-gr89388350ma,Medium;80efffaf-98a1-4e0a-8f5e-gr89388356db,Medium');

  // String masterExecutor = 'cybergeigertoolbox.geiger_toolbox;'
  //     'cybergeigertoolbox.geiger_toolbox.MainActivity;'
  //     'TODO';

  String masterExecutor = 'com.montimage.geiger_api_test;'
      'com.montimage.geiger_api_test.MainActivity;'
      'TODO';

  String pluginExecutor = 'com.montimage.example;'
      'com.montimage.example.MainActivity;'
      'TODO';

  Future<bool> initMasterPlugin() async {
    final bool initGeigerAPI = await masterApiConnector.connectToGeigerAPI(
        masterExecutor: masterExecutor);
    if (initGeigerAPI == false) return false;
    final bool ret = await masterApiConnector.connectToLocalStorage();
    if (ret == false) return false;
    final bool regPluginListener =
        await masterApiConnector.registerPluginListener();
    final bool regStorageListener =
        await masterApiConnector.registerStorageListener();
    isMasterStarted = true;
    return regPluginListener && regStorageListener;
  }

  Future<bool> initExternalPlugin() async {
    final bool initGeigerAPI = await pluginApiConnector.connectToGeigerAPI(
        masterExecutor: masterExecutor, pluginExecutor: pluginExecutor);
    if (initGeigerAPI == false) return false;
    bool ret = await pluginApiConnector.connectToLocalStorage();
    if (ret == false) return false;

    // Prepare some data roots
    ret = await pluginApiConnector.prepareRoot([
      'Device',
      pluginApiConnector.currentDeviceId!,
      montimagePluginId,
      'data',
      'metrics'
    ], '');
    if (ret == false) return false;
    ret = await pluginApiConnector.prepareRoot([
      'Users',
      pluginApiConnector.currentUserId!,
      montimagePluginId,
      'data',
      'metrics'
    ], '');
    if (ret == false) return false;
    ret = await pluginApiConnector.prepareRoot([
      'Chatbot',
      'sensors',
      montimagePluginId,
    ], '');
    if (ret == false) return false;
    // write the plugin information
    ret = await pluginApiConnector.updatePluginNode(
        montimagePluginId, 'My Awesome Plugin', 'Montimage');
    // Prepare some data nodes
    ret = await pluginApiConnector.addDeviceSensorNode(deviceNodeDataModel);
    if (ret == false) return false;
    ret = await pluginApiConnector.addUserSensorNode(userNodeDataModel);
    if (ret == false) return false;

    // Prepare for plugin event handler
    pluginApiConnector.addPluginEventhandler(MessageType.scanPressed,
        (Message msg) async {
      await pluginApiConnector.sendDeviceSensorData(
        deviceNodeDataModel.sensorId,
        Random().nextBool().toString(),
      );
      await pluginApiConnector.sendUserSensorData(
        userNodeDataModel.sensorId,
        Random().nextInt(100).toString(),
      );
    });
    final bool regPluginListener =
        await pluginApiConnector.registerPluginListener();

    // Prepare for storage event handler
    final bool regStorageListener = await pluginApiConnector
        .registerStorageListener(searchPath: ':Chatbot:sensors');
    isExternalPluginStarted = true;
    return regPluginListener && regStorageListener;
  }

  _showSnackBar(String message) {
    SnackBar snackBar = SnackBar(
      content: Text(message),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const TabBar(
            tabs: [
              Tab(
                icon: Icon(
                  Icons.center_focus_strong_outlined,
                ),
                text: 'GeigerToolbox',
              ),
              Tab(
                icon: Icon(Icons.extension_rounded),
                text: 'External Plugin',
              ),
            ],
          ),
        ),
        body: isInProcessing == true
            ? const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.orange,
                ),
              )
            : TabBarView(
                children: [
                  _viewBackendView(),
                  _viewExternalPluginView(),
                ],
              ),
      ),
    );
  }

  _viewBackendView() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 5),
            const Text(
              'GeigerToolbox',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.orange),
            ),
            Text(
              '(geiger_api_connector: ${GeigerApiConnector.version})',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            !isMasterStarted
                ? Column(children: [
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isInProcessing = true;
                        });
                        final bool masterPlugin = await initMasterPlugin();
                        if (masterPlugin == false) {
                          _showSnackBar('Failed to start Master Plugin');
                        } else {
                          _showSnackBar('The Master Plugin has been started');
                        }
                        setState(() {
                          isInProcessing = false;
                        });
                      },
                      child: const Text('Start Master Plugin'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.orange,
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                    const Text('The Master Plugin is not intialized yet!'),
                  ])
                : Column(
                    children: [
                      const Text(
                        'Backend is running...',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.green),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentScanPressed = await masterApiConnector
                              .sendPluginEventType(MessageType.scanPressed);
                          if (sentScanPressed == false) {
                            _showSnackBar('Failed to send SCAN_PRESSED event');
                          } else {
                            _showSnackBar('A SCAN_PRESSED event has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Send SCAN_PRESSED'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          final String storageStr =
                              await masterApiConnector.dumpLocalStorage(':');
                          setState(() {
                            masterOutput = storageStr;
                          });
                        },
                        child: const Text('Dump Storage'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allEventStr =
                              masterApiConnector.showAllPluginEvents();
                          setState(() {
                            masterOutput = allEventStr;
                          });
                        },
                        child: const Text('Show all plugin events'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allStorageStr =
                              masterApiConnector.showAllStorageEvents();
                          setState(() {
                            masterOutput = allStorageStr;
                          });
                        },
                        child: const Text('Show all storage events'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final String? sensorData = await masterApiConnector
                              .readGeigerValueOfDeviceSensor(montimagePluginId,
                                  deviceNodeDataModel.sensorId);
                          setState(() {
                            deviceData = sensorData ?? 'null';
                            masterOutput = 'Device sensors data: $deviceData';
                          });
                        },
                        child: Text(
                            'Show the received device sensor data ($deviceData)'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final String? sensorData = await masterApiConnector
                              .readGeigerValueOfUserSensor(montimagePluginId,
                                  userNodeDataModel.sensorId);
                          setState(() {
                            userData = sensorData ?? 'null';
                            masterOutput = 'User sensors data: $userData';
                          });
                        },
                        child: Text(
                            'Show the received users sensor data ($userData)'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 5),
                      Text(masterOutput != null ? masterOutput! : '<output>'),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  _viewExternalPluginView() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 5),
            const Text(
              'External Plugin',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue),
            ),
            !isExternalPluginStarted
                ? Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool externalPlugin =
                              await initExternalPlugin();
                          if (externalPlugin == false) {
                            _showSnackBar('Failed to start External Plugin');
                          } else {
                            _showSnackBar(
                                'The External Plugin has been started');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Start an External Plugin'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const Text('The external plugin is not initialzed yet!'),
                    ],
                  )
                : Column(
                    children: [
                      const Text(
                        'An external plugin is running...',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.green),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool dataSent =
                              await pluginApiConnector.sendDeviceSensorData(
                                  deviceNodeDataModel.sensorId, "true");
                          if (dataSent == false) {
                            _showSnackBar(
                                'Failed to send a device sensor data');
                          } else {
                            _showSnackBar('A device sensor data has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Send a device data'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool dataSent =
                              await pluginApiConnector.sendUserSensorData(
                                  userNodeDataModel.sensorId, "50");
                          if (dataSent == false) {
                            _showSnackBar('Failed to send a user sensor data');
                          } else {
                            _showSnackBar('A user sensor data has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Send a user data'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          // trigger/send a SCAN_COMPLETED event
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentData = await pluginApiConnector
                              .sendPluginEventType(MessageType.scanCompleted);
                          if (sentData == false) {
                            _showSnackBar(
                                'Failed to send SCAN_COMPLETED event');
                          } else {
                            _showSnackBar(
                                'The SCAN_COMPLETED event has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Send SCAN_COMPLETED event'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          // trigger/send a SCAN_COMPLETED event
                          setState(() {
                            isInProcessing = true;
                          });
                          final String payload = '''{
                            "title":"A message from MI Cyberrange",
                            "message":"You should do more anti-phishing email testing",
                            "timestamp": ${DateTime.now().millisecondsSinceEpoch}
                          }''';
                          final bool sentData = await pluginApiConnector
                              .sendPluginEventWithPayload(
                                  MessageType.customEvent, payload);
                          if (sentData == false) {
                            _showSnackBar(
                                'Failed to send a message with payload');
                          } else {
                            _showSnackBar(
                                'A message with payload has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text(
                            'Send a custom event with payload (json encoded string)'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          // trigger/send a STORAGE_EVENT event
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentData = await pluginApiConnector
                              .sendDataNode(
                                  ':Chatbot:sensors:$montimagePluginId:my-sensor-data',
                                  [
                                'category',
                                'isSubmitted',
                                'threatInfo'
                              ],
                                  [
                                'Malware',
                                'false',
                                'This is the threat info'
                              ]);
                          if (sentData == false) {
                            _showSnackBar('Failed to send data to Chatbot');
                          } else {
                            _showSnackBar('Data has been sent to Chatbot');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        child: const Text('Send a threat info to Chatbot'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allEventStr =
                              pluginApiConnector.showAllPluginEvents();
                          setState(() {
                            pluginOutput = allEventStr;
                          });
                        },
                        child: const Text('Show all plugin events'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allStorageStr =
                              pluginApiConnector.showAllStorageEvents();
                          setState(() {
                            pluginOutput = allStorageStr;
                          });
                        },
                        child: const Text('Show all storage events'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () {
                          pluginApiConnector.sendPluginEventType(
                              MessageType.returningControl);
                        },
                        child: const Text('Back to the GeigerToolbox'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          await pluginApiConnector.close();
                          setState(() {
                            isExternalPluginStarted = false;
                          });
                        },
                        child: const Text('Disconnect'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 5),
                      Text(pluginOutput != null ? pluginOutput! : '<output>'),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
