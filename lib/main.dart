import 'dart:async';
import 'dart:io';
import 'package:dart_jane/vars.dart';
import 'package:dart_openai/openai.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jane Chat GPT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScrollController lvScroll = ScrollController();
  TextEditingController reqTxt = TextEditingController();
  FocusNode labelFocusNode = FocusNode();
  String txtImgDisplay = "L'immagine generata verrà visualizzata qui..";
  TextEditingController reqImgTxt = TextEditingController();
  FocusNode labelImgFocusNode = FocusNode();
  FocusNode labelKeyFocusNode = FocusNode();
  final TextEditingController txtKey = TextEditingController();
  final dio = Dio();

  @override
  void initState() {
    if (Vars.initialized == false) {
      OpenAI.apiKey = Vars.apiKey;
      Future(() {
        initApp();
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return (Vars.selectedTab == 0)
        ? Vars.initialized
            ? Scaffold(
                appBar: AppBar(
                    title: const Text("Jane AI"),
                    titleSpacing: 2.0,
                    leading: PopupMenuButton(
                        position: PopupMenuPosition.under,
                        icon: Image.asset('assets/images/jane.png'),
                        tooltip: "Apri Menu",
                        onSelected: (item) => popupClick(item),
                        itemBuilder: ((context) => [
                              PopupMenuItem(
                                  value: 0,
                                  enabled: Vars.selectedTab == 0 ? false : true,
                                  child: Text(
                                    'Jane Chat',
                                    style: (Vars.selectedTab == 0)
                                        ? const TextStyle(
                                            color: Colors.greenAccent)
                                        : TextStyle(color: Colors.grey[150]),
                                  )),
                              PopupMenuItem(
                                  value: 1,
                                  enabled: Vars.selectedTab == 1 ? false : true,
                                  child: Text(
                                    'Jane Image Gen',
                                    style: (Vars.selectedTab == 1)
                                        ? const TextStyle(
                                            color: Colors.greenAccent)
                                        : TextStyle(color: Colors.grey[150]),
                                  )),
                            ])),
                    backgroundColor: Colors.grey[850],
                    actions: [
                      (Vars.janeBusy == true)
                          ? Padding(
                              padding: const EdgeInsets.only(right: 4, top: 6),
                              child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: Colors.greenAccent, size: 40))
                          : const Padding(padding: EdgeInsets.only(right: 8)),
                      IconButton(
                          onPressed: () {
                            lvScroll.animateTo(
                                lvScroll.position.maxScrollExtent,
                                duration: const Duration(seconds: 1),
                                curve: Curves.fastOutSlowIn);
                          },
                          icon: const Icon(
                              CupertinoIcons.arrow_down_circle_fill)),
                      IconButton(
                          onPressed: () {
                            lvScroll.animateTo(
                                lvScroll.position.minScrollExtent,
                                duration: const Duration(seconds: 1),
                                curve: Curves.fastOutSlowIn);
                          },
                          icon:
                              const Icon(CupertinoIcons.arrow_up_circle_fill)),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                            icon:
                                const Icon(CupertinoIcons.clear_circled_solid),
                            tooltip: "Cancella Conversazione",
                            onPressed: () {
                              deleteChat();
                            }),
                      ),
                    ]),
                body: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(
                            left: 16, top: 8, right: 16, bottom: 8),
                        itemCount: Vars.displayMessages.length,
                        controller: lvScroll,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          return RichText(
                              text: TextSpan(
                                  style: const TextStyle(color: Colors.white),
                                  children: <TextSpan>[
                                TextSpan(
                                    text:
                                        "${Vars.displayMessages[index].toString().split(' ')[0]} ",
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text: Vars.displayMessages[index]
                                        .toString()
                                        .split(' ')
                                        .sublist(1)
                                        .join(' '))
                              ]));
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            const Divider(
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8, left: 6, right: 6),
                        child: TextField(
                          focusNode: labelFocusNode,
                          maxLines: 1,
                          onTapOutside: (event) => {
                            (MediaQuery.of(context).viewInsets.bottom) == 0
                                ? null
                                : FocusScope.of(context).unfocus()
                          },
                          cursorHeight: 22.0,
                          cursorColor: Colors.grey,
                          controller: reqTxt,
                          decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(32))),
                              border: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(32))),
                              focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(32)),
                                  borderSide: BorderSide(
                                      color: Color.fromRGBO(105, 240, 174, 1))),
                              labelText: labelFocusNode.hasFocus
                                  ? ''
                                  : 'Scrivi a Jane',
                              labelStyle: const TextStyle(color: Colors.grey)),
                          onSubmitted: (value) {
                            reqTxt.text = "";
                            submitRequestAI(value).whenComplete(() {
                              Timer(const Duration(milliseconds: 800), () {
                                lvScroll.animateTo(
                                    lvScroll.position.maxScrollExtent + 1.0,
                                    duration: const Duration(seconds: 1),
                                    curve: Curves.fastOutSlowIn);
                              });
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      (Vars.showInitButton == false)
                          ? const Text("Attendi..",
                              style: TextStyle(
                                  color: Colors.greenAccent, fontSize: 20))
                          : Text(Vars.initError_1,
                              style: const TextStyle(
                                  color: Colors.greenAccent, fontSize: 20)),
                      (Vars.showInitButton == false)
                          ? const Text("Avvio l'applicazione...",
                              style: TextStyle(
                                  color: Colors.greenAccent, fontSize: 20))
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(Vars.initError_2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.greenAccent, fontSize: 20)),
                            ),
                      (Vars.showInitButton == true)
                          ? const Padding(
                              padding: EdgeInsets.only(top: 24.0),
                              child: Text("Riproviamo insieme!",
                                  style: TextStyle(
                                      color: Colors.greenAccent, fontSize: 20)),
                            )
                          : const Padding(padding: EdgeInsets.all(0)),
                      (Vars.showInitButton == false)
                          ? Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: LoadingAnimationWidget.stretchedDots(
                                  color: Colors.greenAccent, size: 54),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: OutlinedButton(
                                onPressed: () {
                                  Vars.showInitButton = false;
                                  setState(() {
                                    Vars.showInitButton = Vars.showInitButton;
                                  });
                                  initApp();
                                },
                                style: const ButtonStyle(
                                    foregroundColor:
                                        MaterialStatePropertyAll<Color>(
                                            Colors.greenAccent)),
                                child: const Text(
                                    "Riprova ad inizializzare l'App"),
                              ))
                    ],
                  ),
                ),
              )
        : Scaffold(
            appBar: AppBar(
              title: const Text("Jane AI"),
              titleSpacing: 2.0,
              leading: PopupMenuButton(
                  position: PopupMenuPosition.under,
                  icon: Image.asset('assets/images/jane.png'),
                  tooltip: "Apri Menu",
                  onSelected: (item) => popupClick(item),
                  itemBuilder: ((context) => [
                        PopupMenuItem(
                            value: 0,
                            enabled: Vars.selectedTab == 0 ? false : true,
                            child: Text(
                              'Jane Chat',
                              style: (Vars.selectedTab == 0)
                                  ? const TextStyle(color: Colors.greenAccent)
                                  : TextStyle(color: Colors.grey[150]),
                            )),
                        PopupMenuItem(
                            value: 1,
                            enabled: Vars.selectedTab == 1 ? false : true,
                            child: Text(
                              'Jane Image Gen',
                              style: (Vars.selectedTab == 1)
                                  ? const TextStyle(color: Colors.greenAccent)
                                  : TextStyle(color: Colors.grey[150]),
                            )),
                      ])),
              backgroundColor: Colors.grey[850],
              actions: [
                (Vars.generatingImg == true)
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: LoadingAnimationWidget.hexagonDots(
                            color: Colors.greenAccent, size: 40),
                      )
                    : const Padding(padding: EdgeInsets.only(right: 2)),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled_solid),
                      tooltip: "Cancella Immagine",
                      onPressed: () {
                        Vars.imgLink = "";
                        setState(() {
                          Vars.imgLink = Vars.imgLink;
                        });
                      }),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: (Vars.errorImgMsg == "")
                      ? Center(
                          child: (Vars.imgLink != "")
                              ? Column(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onLongPress: () {
                                          saveImg();
                                        },
                                        child: Image(
                                          image: NetworkImage(Vars.imgLink),
                                          frameBuilder: (context, child, frame,
                                              wasSynchronouslyLoaded) {
                                            return Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: child);
                                          },
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              Vars.imageReady = true;
                                              return child;
                                            }
                                            return Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 16),
                                                  child: Text(
                                                      "Attendi.. sto elaborando l'immagine..."),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 16.0),
                                                  child: Center(
                                                    child: LoadingAnimationWidget
                                                        .stretchedDots(
                                                            color: Colors
                                                                .greenAccent,
                                                            size: 100),
                                                  ),
                                                )
                                              ],
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Center(
                                              child: Text(
                                                  "C'è stato un errore nel caricare l'immagine.."),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Vars.imageReady
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                                top: 8.0, bottom: 8.0),
                                            child: OutlinedButton(
                                              onPressed: () {
                                                submitRequestImg(
                                                    Vars.lastImgRequested);
                                              },
                                              style: const ButtonStyle(
                                                  foregroundColor:
                                                      MaterialStatePropertyAll<
                                                              Color>(
                                                          Colors.greenAccent)),
                                              child: const Text(
                                                  "Genera immagine variante"),
                                            ),
                                          )
                                        : const Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 8.0)),
                                  ],
                                )
                              : Text(txtImgDisplay))
                      : Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Center(
                              child: Text(Vars.errorImgMsg),
                            ),
                          ),
                        ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(bottom: 8, left: 6, right: 6),
                    child: TextField(
                      focusNode: labelImgFocusNode,
                      maxLines: 1,
                      onTapOutside: (event) => {
                        (MediaQuery.of(context).viewInsets.bottom) == 0
                            ? null
                            : FocusScope.of(context).unfocus()
                      },
                      cursorHeight: 22.0,
                      cursorColor: Colors.grey,
                      //keyboardType: TextInputType.text,
                      controller: reqImgTxt,
                      decoration: InputDecoration(
                          enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(32))),
                          border: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(32))),
                          focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(32)),
                              borderSide: BorderSide(
                                  color: Color.fromRGBO(105, 240, 174, 1))),
                          labelText: labelImgFocusNode.hasFocus
                              ? ''
                              : "Chiedi un'immagine a Jane",
                          labelStyle: const TextStyle(color: Colors.grey)),
                      onSubmitted: (value) {
                        reqImgTxt.text = "";
                        submitRequestImg(value);
                      },
                    ),
                  ),
                ),
              ],
            ));
  }

  Future submitRequestAI(String txt) async {
    if (txt != "") {
      Vars.janeBusy = true;
      Vars.displayMessages.add("Tu: $txt");
      Vars.displayMessages.add("Jane sta scrivendo...");
      setState(() {
        Vars.displayMessages = Vars.displayMessages;
      });

      Timer(const Duration(milliseconds: 500), () {
        lvScroll.animateTo(lvScroll.position.maxScrollExtent,
            duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
      });

      try {
        Vars.messages.add(OpenAIChatCompletionChoiceMessageModel(
            content: txt, role: OpenAIChatMessageRole.user));

        OpenAIChatCompletionModel chatCompletion = await OpenAI.instance.chat
            .create(
              model: "gpt-3.5-turbo",
              messages: Vars.messages,
              temperature: 1.0,
            )
            .timeout(const Duration(minutes: 2));

        Vars.messages.add(OpenAIChatCompletionChoiceMessageModel(
            content: chatCompletion.choices[0].message.content.toString(),
            role: OpenAIChatMessageRole.assistant));

        Vars.displayMessages.removeLast();
        Vars.displayMessages.add(
            "Jane: ${chatCompletion.choices[0].message.content.toString().trim()}");
        Vars.janeBusy = false;

        setState(() {
          Vars.janeBusy = Vars.janeBusy;
          Vars.displayMessages = Vars.displayMessages;
        });
      } on SocketException {
        Vars.displayMessages.removeLast();
        Vars.displayMessages.add(
            "App: Errore connettività. Controlla la tua connessione Internet!");
        Vars.janeBusy = false;
      } on TimeoutException {
        Vars.displayMessages.removeLast();
        Vars.displayMessages.add(
            "App: Errore timeout, è possibile che al momento le richieste a Chat GPT siano troppe, riprova!");
        Vars.janeBusy = false;
      } catch (err) {
        Vars.displayMessages.removeLast();
        Vars.displayMessages.add(
            "App: Errore nella richiesta. Riprova a breve! Se il problema persiste controlla la validità della API Key.");
        Vars.janeBusy = false;
      }
      setState(() {
        Vars.displayMessages = Vars.displayMessages;
      });
    }
  }

  Future submitRequestImg(String req) async {
    Vars.generatingImg = true;
    Vars.imageReady = false;
    Vars.lastImgRequested = req;
    Vars.imgLink = "";
    Vars.errorImgMsg = "";
    txtImgDisplay = "Invio la richiesta.. Attendi...";
    setState(() {
      Vars.generatingImg = Vars.generatingImg;
      Vars.errorImgMsg = Vars.errorImgMsg;
      Vars.imgLink = Vars.imgLink;
      txtImgDisplay = txtImgDisplay;
    });
    try {
      OpenAIImageModel image = await OpenAI.instance.image.create(
        prompt: req,
        n: 1,
        size: OpenAIImageSize.size1024,
        responseFormat: OpenAIImageResponseFormat.url,
      );
      Vars.generatingImg = false;
      Vars.imgLink = image.data[0].url!;
      Vars.errorImgMsg = "";
      txtImgDisplay = "L'immagine generata verrà visualizzata qui..";

      setState(() {
        Vars.imgLink = Vars.imgLink;
        Vars.generatingImg = false;
        Vars.errorImgMsg = Vars.errorImgMsg;
        txtImgDisplay = txtImgDisplay;
      });
    } on SocketException {
      Vars.errorImgMsg =
          "Errore di Connessione. Collegati ad Internet e riprova!";
      Vars.generatingImg = false;
      setState(() {
        Vars.errorImgMsg = Vars.errorImgMsg;
        Vars.generatingImg = Vars.generatingImg;
      });
    } catch (err) {
      Vars.errorImgMsg =
          "Errore imprevisto, contatta lo sviluppatore se il problema persiste!";
      Vars.generatingImg = false;
      setState(() {
        Vars.errorImgMsg = Vars.errorImgMsg;
        Vars.generatingImg = Vars.generatingImg;
      });
    }
  }

  void saveImg() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        Vars.generatingImg = true;
        setState(() {
          Vars.generatingImg = Vars.generatingImg;
        });
        var response = await Dio().get(Vars.imgLink,
            options: Options(responseType: ResponseType.bytes));
        await ImageGallerySaver.saveImage(Uint8List.fromList(response.data),
            quality: 60);

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Immagine salvata con successo!",
            style: TextStyle(color: Colors.greenAccent),
          ),
          backgroundColor: Colors.black45,
          duration: Duration(milliseconds: 1500),
        ));
        Vars.generatingImg = false;
        setState(() {
          Vars.generatingImg = Vars.generatingImg;
        });
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            "Autorizzazione non concessa..",
            style: TextStyle(color: Colors.greenAccent),
          ),
          backgroundColor: Colors.black45,
          duration: Duration(milliseconds: 1500),
        ));
        Future.delayed(const Duration(milliseconds: 1500), openAppSettings);
      }
    }
  }

  Future initApp() async {
    await initAI().whenComplete(() {
      if (Vars.showInitButton == false) {
        Timer(const Duration(seconds: 2), () {
          Vars.initialized = true;
          setState(() {
            Vars.initialized = Vars.initialized;
          });
        });
      }
    });
  }

  Future initAI() async {
    try {
      await OpenAI.instance.chat
          .create(
            model: "gpt-3.5-turbo",
            messages: [
              const OpenAIChatCompletionChoiceMessageModel(
                  content:
                      "Sei un assistente virtuale chiamata Jane, e parli italiano.",
                  role: OpenAIChatMessageRole.system)
            ],
            temperature: 1.0,
          )
          .timeout(const Duration(seconds: 30));

      Vars.messages.add(const OpenAIChatCompletionChoiceMessageModel(
          content:
              "Sei un assistente virtuale chiamata Jane, e parli italiano.",
          role: OpenAIChatMessageRole.system));
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "App inizializzata con successo. Ti porto alla Home!",
          style: TextStyle(color: Colors.greenAccent),
        ),
        backgroundColor: Colors.black45,
        duration: Duration(milliseconds: 1500),
      ));
      Vars.showInitButton = false;
    } on SocketException {
      Vars.initError_1 = "C'è un problema..";
      Vars.initError_2 = "E' necessaria una connessione internet attiva.";
      Vars.showInitButton = true;
    } on TimeoutException {
      Vars.initError_1 = "C'è un problema..";
      Vars.initError_2 = "Pare ci siano troppe richieste al momento.";
      Vars.showInitButton = true;
    } on RequestFailedException {
      Vars.initError_1 = "C'è un problema..";
      Vars.initError_2 =
          "Errore nell'inizializzare Chat GPT, controlla la API Key. Sembra essere un problema circa la scadenza della Key o del raggiungimento massimo della quota.";
      Vars.showInitButton = true;
    } catch (err) {
      Vars.initError_1 = "C'è un problema..";
      Vars.initError_2 =
          "Errore imprevisto, controlla la API Key. Se il problema persiste, contattami! $err";
      Vars.showInitButton = true;
    }
    setState(() {
      Vars.showInitButton = Vars.showInitButton;
      Vars.initError_1 = Vars.initError_1;
      Vars.initError_2 = Vars.initError_2;
    });
  }

  void deleteChat() {
    Vars.displayMessages.clear();
    Vars.displayMessages.add(
        'Jane: Il mio nome è Jane e sono un assistente virtuale a tua disposizione.');
    setState(() {
      Vars.displayMessages = Vars.displayMessages;
    });
    Vars.messages.clear();
    Vars.messages.add(const OpenAIChatCompletionChoiceMessageModel(
        content: "Sei un assistente virtuale chiamata Jane, e parli italiano.",
        role: OpenAIChatMessageRole.system));
  }

  void popupClick(int item) async {
    switch (item) {
      case 0:
        {
          Vars.selectedTab = 0;
          setState(() {
            Vars.selectedTab = Vars.selectedTab;
          });
          break;
        }
      case 1:
        {
          Vars.selectedTab = 1;
          setState(() {
            Vars.selectedTab = Vars.selectedTab;
          });
          break;
        }
    }
  }
}
