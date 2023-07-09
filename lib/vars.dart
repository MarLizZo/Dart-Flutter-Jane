import 'package:dart_openai/openai.dart';

class Vars {
  static List<OpenAIChatCompletionChoiceMessageModel> messages = [];
  static List<String> displayMessages = [
    'Jane: Il mio nome è Jane e sono un assistente virtuale a tua disposizione.'
  ];
  static bool initialized = false;
  static bool janeBusy = false;
  static int selectedTab = 0;
  static String apiKey = "your_api_key";
  static bool usingDefaultKey = true;
  static bool generatingImg = false;
  static bool imageReady = false;
  static String initError_1 = "";
  static String initError_2 = "";
  static String imgLink = "";
  static String errorImgMsg = "";
  static String lastImgRequested = "";
  static bool showInitButton = false;
}
