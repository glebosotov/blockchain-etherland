import 'dart:developer';

import 'package:blockchain_week5/meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web3/flutter_web3.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Etherland',
      theme: ThemeData(
        platform: TargetPlatform.android,
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.brown,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void setupEth() async {
    // From RPC
    final web3provider = Web3Provider(ethereum!);

    busd = Contract(
      contractAddress,
      Interface(abi),
      web3provider.getSigner(),
    );

    try {
      // Prompt user to connect to the provider, i.e. confirm the connection modal
      final accs =
          await ethereum!.requestAccount(); // Get all accounts in node disposal
      accs; // [foo,bar]
    } on EthereumUserRejected {
      log('User rejected the modal');
    }
  }

  late Contract busd;

  @override
  void initState() {
    setupEth();
    super.initState();
  }

  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  void callReadOnlyMethod(String method, List<dynamic> args) async {
    try {
      final result = await busd.call(method, args);
      showToast(result.toString());
    } catch (e) {
      showToast(e.toString());
    }
  }

  void callPayableMethod(String method, List<dynamic> args) async {
    final navigator = Navigator.of(context);
    try {
      final send = await busd.send(
        method,
        args,
        TransactionOverride(
          value: BigInt.from(args[3]) *
              BigInt.parse('1000000000000000' /*10^16 + 1*/),
        ),
      );
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
                child: SizedBox(
                  height: 10,
                  width: 300,
                  child: LinearProgressIndicator(),
                ),
              ));
      final result = await send.wait();
      navigator.pop();
      showToast(result.logs.map((e) => e.data).join(' ').toString());
      // showToast(result.logs.toString());
    } on EthereumException catch (e) {
      final String message = e.data['message'];
      if (message.contains('Collision')) {
        showToast('Somebody owns that land already');
      } else {
        showToast(message);
      }
    }
  }

  final latController = TextEditingController();
  final lngController = TextEditingController();
  var radius = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              LimitedBox(
                maxWidth: 200,
                child: TextField(
                  controller: latController,
                  decoration: const InputDecoration(hintText: 'Lat'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
              LimitedBox(
                maxWidth: 200,
                child: TextField(
                  controller: lngController,
                  decoration: const InputDecoration(hintText: 'Lon'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
              Slider(
                min: 1,
                max: 10000,
                divisions: 10000,
                value: radius.toDouble(),
                label: '$radius meters',
                onChanged: (newRadius) {
                  setState(() {
                    radius = newRadius.toInt();
                  });
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    final address = await busd.signer!.getAddress();
                    callPayableMethod('publicMint', [
                      address,
                      double.parse(latController.text) * 1000000,
                      double.parse(lngController.text) * 1000000,
                      radius,
                    ]);
                  },
                  child: const Text('Purchase land')),
            ],
          ),
        ),
      ),
    );
  }
}
