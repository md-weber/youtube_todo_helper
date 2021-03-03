import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_browser.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

void prompt(String url) {
  print("Please go to the following URL and grant access:");
  print("  => $url");
  print("");
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var apiKey = "AIzaSyAMNk-N70f4_No_iboyW846CvIx1mX6xuc";
  AccessCredentials credentials;
  List<String> todoCommands = [];
  Timer timer;

  @override
  void initState() {
    super.initState();
    initializeCredentials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(todoCommands[index]),
                  );
                },
                itemCount: todoCommands.length,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (credentials == null) return;
                  final client = http.Client();
                  print(credentials.accessToken.data);
                  try {
                    Map<String, String> headers = {
                      "Authorization":
                          "${credentials.accessToken.type} ${credentials.accessToken.data}"
                    };

                    final http.Response response = await client.get(
                      "https://youtube.googleapis.com/youtube/v3/liveBroadcasts?part=snippet&broadcastStatus=active&key=$apiKey",
                      headers: headers,
                    );

                    if (response.statusCode == 200) {
                      Map<String, dynamic> responseBody =
                          jsonDecode(response.body);
                      var liveChatId =
                          responseBody["items"][0]["snippet"]["liveChatId"];

                      timer = Timer(Duration(seconds: 30), () async {
                        final http.Response liveChatResponse = await client.get(
                          "https://youtube.googleapis.com/youtube/v3/liveChat/messages?liveChatId=$liveChatId&part=snippet&key=$apiKey",
                          headers: headers,
                        );

                        if (liveChatResponse.statusCode == 200) {
                          Map<String, dynamic> liveChat =
                              jsonDecode(liveChatResponse.body);

                          List<String> latestChatMessages = [];
                          for (final chat in liveChat["items"]) {
                            var displayMessage =
                                chat["snippet"]["displayMessage"];
                            latestChatMessages.add(displayMessage);
                          }

                          setState(() {
                            todoCommands = latestChatMessages
                                .where((element) => element.startsWith("!TODO"))
                                .map((element) =>
                                    element.substring(5, element.length))
                                .toList();
                          });
                        } else {
                          timer.cancel();
                        }
                      });
                    }

                    if (response.statusCode == 403) {
                      print(
                          "Unauthorized: ${jsonDecode(response.body).toString()}");
                    }
                  } catch (e) {
                    print(e.toString());
                  }
                },
                child: Text("Login to Google Service"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> initializeCredentials() async {
    if (credentials == null) {
      var client = http.Client();

      var id = kIsWeb
          ? ClientId(
              "937172575378-kj0c25qrnj3mhm0c3pmhn98737igm2pp.apps.googleusercontent.com",
              "Wxbu62wk3Bk28IO6QT2jVDh_")
          : ClientId(
              "937172575378-k28h4qocuuiur2blnj925p1rt04bck0l.apps.googleusercontent.com",
              "T6Sn-4mE3ivLLWpgT_chIGyI",
            );

      List<String> scopes = [
        "https://www.googleapis.com/auth/youtube.readonly",
      ];

      if (kIsWeb) {
        BrowserOAuth2Flow browserOAuth2Flow =
            await createImplicitBrowserFlow(id, scopes);
        credentials =
            await browserOAuth2Flow.obtainAccessCredentialsViaUserConsent();
      } else {
        credentials = await obtainAccessCredentialsViaUserConsent(
            id, scopes, client, prompt);
      }
    }
  }
}
