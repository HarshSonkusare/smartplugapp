import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'EnergyModel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart PLug',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (context) => const HomePage(title: 'Smart Plug'),
        '/smartplug': (context) => const SmartPlug()
      },
    );
  }
}

Future<EnergyModel> getEnergy() async {
  final response = await http
      .get(Uri.parse('https://smartplug123.onrender.com/api/getEnergy'));
  if (response.statusCode == 200) {
    final jsonEnergy = jsonDecode(response.body);
    return EnergyModel.fromJason(jsonEnergy);
  } else {
    throw Exception();
  }
}

class EnergyData {
  EnergyData(this.energy, this.time);
  final double energy;
  final double time;
}

class SmartPlug extends StatefulWidget {
  const SmartPlug({super.key});

  @override
  State<SmartPlug> createState() => _SmartPlugState();
}

class _SmartPlugState extends State<SmartPlug> {
  int index = 0;
  bool status = false;

  void getStatus() async {
    final response = await http
        .get(Uri.parse('https://smartplug123.onrender.com/api/getStatus'));
    if (response.statusCode == 200) {
      final jsonStatus = jsonDecode(response.body);
      bool statusVal;
      if (jsonStatus['status'] == 1) {
        statusVal = true;
      } else {
        statusVal = false;
      }
      setState(() {
        status = statusVal;
      });
    } else {
      throw Exception();
    }
  }

  void updateStatus(bool value) async {
    var val = 0;
    if (value) {
      val = 1;
    }
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST',
        Uri.parse('https://smartplug123.onrender.com/api/updateStatus'));
    request.body = json.encode({"status": val});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
    } else {
      throw Exception();
    }
  }

  List<EnergyData> getChartData(final day, final week, final month) {
    List<EnergyData> chartData = [];
    if (index == 0) {
      var len = day.length;
      for (var i = len - 1; i >= 0; i--) {
        chartData.add(EnergyData(day[i], 23.0 - i));
      }
      for (var i = len; i < 24; i++) {
        chartData.add(EnergyData(0, i - len));
      }
      return chartData;
    } else if (index == 1) {
      var len = week.length;
      for (var i = len - 1; i >= 0; i--) {
        chartData.add(EnergyData(week[i], 7.0 - i));
      }
      for (var i = len; i < 7; i++) {
        chartData.add(EnergyData(0, i - len + 1));
      }
      return chartData;
    } else {
      var len = month.length;
      for (var i = len - 1; i >= 0; i--) {
        chartData.add(EnergyData(month[i], 30.0 - i));
      }
      for (var i = len; i < 30; i++) {
        chartData.add(EnergyData(0, i - len + 1));
      }
      return chartData;
    }
  }

  @override
  void initState() {
    super.initState();
    getStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Center(child: Text('Laptop'))),
        body: Center(
            child: FutureBuilder<EnergyModel>(
                future: getEnergy(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final energy = snapshot.data;

                    final day = energy == null ? [] : energy.day;
                    final week = energy == null ? [] : energy.week;
                    final month = energy == null ? [] : energy.month;
                    final String duration;
                    List<Color> color = [Colors.grey, Colors.grey, Colors.grey];
                    if (index == 0) {
                      color[0] = Colors.red;
                      duration = 'Day';
                    } else if (index == 1) {
                      color[1] = Colors.red;
                      duration = 'Week';
                    } else {
                      color[2] = Colors.red;
                      duration = 'Month';
                    }

                    final chartData = getChartData(day, week, month);
                    return SafeArea(
                        child: Center(
                            child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Center(
                            child: SwitchListTile(
                          title: const Text('Laptop Status'),
                          value: status,
                          onChanged: (bool value) {
                            setState(() {
                              status = value;
                            });
                            updateStatus(value);
                          },
                          secondary:
                              const Icon(Icons.laptop_chromebook_outlined),
                        )),
                        Padding(
                            padding: const EdgeInsets.all(20),
                            child:
                                Text('Total Energy Consumption in $duration')),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(color: color[2], width: 1)),
                                onPressed: () {
                                  setState(() {
                                    index = 2;
                                  });
                                },
                                child: const Text('Month')),
                            OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(color: color[1], width: 1)),
                                onPressed: () {
                                  setState(() {
                                    index = 1;
                                  });
                                },
                                child: const Text('Week')),
                            OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(color: color[0], width: 1)),
                                onPressed: () {
                                  setState(() {
                                    index = 0;
                                  });
                                },
                                child: const Text('Day')),
                          ],
                        ),
                        SfCartesianChart(
                          series: <ChartSeries>[
                            LineSeries<EnergyData, double>(
                                dataSource: chartData,
                                xValueMapper: (EnergyData energy, _) =>
                                    energy.time,
                                yValueMapper: (EnergyData energy, _) =>
                                    energy.energy)
                          ],
                        ),
                      ],
                    )));
                  } else if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  return const CircularProgressIndicator();
                })));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text(title))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'List of connected Devices to Smart Plug : ',
              ),
            ),
            Column(
              children: <Widget>[
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/smartplug');
                  },
                  child: const Padding(
                      padding: EdgeInsets.fromLTRB(150, 10, 150, 10),
                      child: Text('Laptop')),
                )
              ],
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add new Device',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
