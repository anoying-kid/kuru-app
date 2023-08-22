import 'dart:async';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kururin/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class KururinScreen extends StatefulWidget {
  const KururinScreen({super.key});

  @override
  State<KururinScreen> createState() => _KururinScreenState();
}

class _KururinScreenState extends State<KururinScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isCurrentUserFetched = false;
  @override
  void initState()  {
    super.initState();
    _initializeCurrentUser();
  }

  Future<void> _initializeCurrentUser() async {
    final userAuth = Provider.of<AuthProvider>(context, listen: false);

    if (!_isCurrentUserFetched) {
      if (_auth.currentUser != null) {
        userAuth.fetchSetCurrentUser();
      } else {
        int locallySavedKuruCount = await getIntLocally() ?? 0;
        userAuth.setKuruCount = locallySavedKuruCount;
      }
      setState(() {
        _isCurrentUserFetched = true;
      });
    }
  }

  Future<int?> getIntLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('kuruCount');
  }

  Future<void> saveIntLocally(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kuruCount', value);
  }

  final List<Widget> _animationWidgets = []; // List to store animation widgets
  Timer? _buttonTimer;

  void _onButtonPressed() async {
    final userAuth = Provider.of<AuthProvider>(context, listen: false);
    userAuth.addKuruCount();
    await saveIntLocally(userAuth.kuruCount);
    _playSound();
    _startTimer();
    _animationWidgets.add(const KururinAnimation()); // Add animation to list
    setState(() {});
  }

  void _playSound() async {
    Random random = Random();
    int randomNumber = random.nextInt(2);
    AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
    List<String> songList = [
      'assets/audios/kuru1.mp3',
      'assets/audios/kuru2.mp3'
    ];
    await audioPlayer.open(
      Audio(
        songList[randomNumber],
      ),
    );
  }

  void _startTimer() {
    if (_buttonTimer != null && _buttonTimer!.isActive) {
      _buttonTimer!.cancel(); // Reset timer if button is pressed again
    }
    _buttonTimer = Timer(const Duration(milliseconds: 1500), () {
      setState(() {
        _animationWidgets.clear();
      });
    });
  }

  static final Uri _githubUrl = Uri.parse('https://github.com/anoying-kid');
  Future<void> _launchUrl() async {
    if (!await launchUrl(_githubUrl)) {
      throw Exception('Could not launch $_githubUrl');
    }
  }

  bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width <=
        500; // Adjust the width threshold as needed
  }

  Widget buildText(BuildContext context) {
    if (isSmallScreen(context)) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You got',
            style: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Kuru Kurued!',
            style: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return const Text(
        'You got Kuru Kurued!!!!!',
        style: TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  void _leaderBoard(BuildContext context) async {
    bool isLoading = true;
    List<Map<String, dynamic>> userKuruCount = [];
    await FirebaseFirestore.instance
        .collection('userKuruCount')
        .orderBy('kuruCount', descending: true)
        .limit(3)
        .get()
        .then((querySnapshot) {
      for (var element in querySnapshot.docs) {
        userKuruCount.add(element.data());
      }
      setState(() {
        isLoading = false;
      });
    });

    List<DataRow> dataRow() {
      List<DataRow> dataRows = [];
      int rank = 1;
      for (var user in userKuruCount) {
        // print(user);
        dataRows.add(DataRow(cells: [
          DataCell(Text(rank.toString())),
          DataCell(Text(user['displayName'])),
          DataCell(Text(user['kuruCount'].toString())),
        ]));
        rank += 1;
      }
      return dataRows;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Leaderboard'),
            content: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : DataTable(
                    columns: const [
                      DataColumn(label: Text('Rank')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Kuru Score')),
                    ],
                    rows: [
                      ...dataRow(),
                    ],
                  ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      body: Stack(children: [
        Align(
            alignment: Alignment.topCenter,
            child: Image.asset('assets/gifs/kuru1.gif')),
        Container(
          width: double.infinity,
          color: const Color.fromARGB(255, 127, 68, 255).withOpacity(0.99),
          child: Stack(
            children: [
              ..._animationWidgets, // Show all animation widgets
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildText(context),
                  Center(
                    child: Consumer<AuthProvider>(
                      builder: (context, userAuth, _) {
                        return Text(
                          userAuth.kuruCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 30,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  GestureButton(
                    onButtonPressed: _onButtonPressed,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                          iconSize: 60,
                          onPressed: _launchUrl,
                          icon: Image.asset('assets/images/github.png')),
                      IconButton(
                          iconSize: 60,
                          onPressed: () async {
                            if (FirebaseAuth.instance.currentUser == null) {
                              // print('Not');
                              try {
                                await userAuth.signInWithGoogle();
                              } on PlatformException catch (error) {
                                if (error.code == 'sign_in_canceled') {
                                  // Checks for sign_in_canceled exception
                                  debugPrint('Sign In Canceled');
                                } else {
                                  rethrow; // Throws PlatformException again because it wasn't the one we wanted
                                }
                              }
                            } else {
                              // print('Yes');
                              _leaderBoard(context);
                            }
                          },
                          icon: Image.asset('assets/images/leaderboard.png')),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ]),
    );
  }
}

class GestureButton extends StatefulWidget {
  final Function onButtonPressed;
  const GestureButton({required this.onButtonPressed, super.key});

  @override
  State<GestureButton> createState() => _GestureButtonState();
}

class _GestureButtonState extends State<GestureButton> {
  static const double _shadowHeight = 4;
  double _position = 4;
  @override
  Widget build(BuildContext context) {
    const double height = 64 - _shadowHeight;
    return InkWell(
      onTapUp: (_) {
        setState(() {
          _position = 4;
        });
      },
      onTapDown: (_) {
        widget.onButtonPressed();
        setState(() {
          _position = 0;
        });
      },
      onTapCancel: () {
        setState(() {
          _position = 4;
        });
      },
      child: SizedBox(
        height: height + _shadowHeight,
        width: 200,
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              child: Container(
                height: height,
                width: 200,
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.all(
                    Radius.circular(16),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              curve: Curves.easeIn,
              bottom: _position,
              duration: const Duration(milliseconds: 70),
              child: Container(
                height: height,
                width: 200,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 167, 126, 255),
                  borderRadius: BorderRadius.all(
                    Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Kuru Kuru',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KururinAnimation extends StatefulWidget {
  const KururinAnimation({super.key});

  @override
  State<KururinAnimation> createState() => _KururinAnimationState();
}

class _KururinAnimationState extends State<KururinAnimation> {
  int randomNumber = Random().nextInt(2);
  bool _visible = true;
  @override
  void initState() {
    super.initState(); //when this route starts, it will execute this code
    Future.delayed(const Duration(milliseconds: 1500), () {
      //asynchronous delay
      if (mounted) {
        //checks if widget is still active and not disposed
        setState(() {
          //tells the widget builder to rebuild again because ui has updated
          _visible =
              false; //update the variable declare this under your class so its accessible for both your widget build and initState which is located under widget build{}
        });
      }
    });
  }

  static const List<String> _songList = [
    'assets/gifs/kuru1.gif',
    'assets/gifs/kuru2.gif'
  ];
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _visible,
      child: TweenAnimationBuilder(
        tween: Tween(begin: 1.0, end: -1.0),
        duration: const Duration(milliseconds: 1500),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(value * 1000.0, 0.0),
            child: child,
          );
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: Image.asset(_songList[randomNumber]),
        ),
      ),
    );
  }
}
