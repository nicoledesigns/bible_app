import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'pages/home.dart';  
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ add this
import 'pages/chat.dart';




// ✅ Make main async to load .env first
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // ✅ load API key for BiblicalChatPage
  runApp(const BibleApp());
}
class HomeNavigation extends StatefulWidget {
  final String bibleVersion;
  final Function(String) onSelectVersion;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeNavigation({
    super.key,
    required this.bibleVersion,
    required this.onSelectVersion,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _selectedIndex = 1; // Default to Bible page

  @override
  Widget build(BuildContext context) {
    // List of pages. Replace MainPage and BibleSearchPage with your real pages.
    final List<Widget> pages = [
      MainPage(),
      BibleChapterView(
        bibleVersion: widget.bibleVersion,
        onSelectVersion: widget.onSelectVersion,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      const BiblicalChatPage(),  // ✅ add your Biblical AI chat page as a tab

        // Placeholder for BibleSearchPage
  //Center(child: Text("Bible Search Coming Soon!")),
   // BibleSearchPage(),

    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Main',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Bible',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

class BibleApp extends StatefulWidget {
  const BibleApp({super.key});
  @override
  State<BibleApp> createState() => _BibleAppState();
}

class _BibleAppState extends State<BibleApp> {
  ThemeMode _themeMode = ThemeMode.light;
  String _bibleVersion = 'ESV';


  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _selectVersion(String version) {
    setState(() {
      _bibleVersion = version;
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Bible',
      theme: ThemeData(primarySwatch: Colors.brown, brightness: Brightness.light),
      darkTheme: ThemeData(primarySwatch: Colors.brown, brightness: Brightness.dark),
      themeMode: _themeMode,
 home: HomeNavigation(
  bibleVersion: _bibleVersion,
  onSelectVersion: _selectVersion,
  onToggleTheme: _toggleTheme,
  isDarkMode: _themeMode == ThemeMode.dark,
),

    );
  }
}

class BibleChapterView extends StatefulWidget {
  final String bibleVersion;
  final Function(String) onSelectVersion;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const BibleChapterView({
    super.key,
    required this.bibleVersion,
    required this.onSelectVersion,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<BibleChapterView> createState() => _BibleChapterViewState();
} 
enum TtsState { playing, paused, stopped }

class _BibleChapterViewState extends State<BibleChapterView> {
  TtsState ttsState = TtsState.stopped;
  int? currentReadingVerseIndex;
  bool isPaused = false;
  Future<void> _stopTts() async {
  await flutterTts.stop();
}
  Map<String, dynamic> bibleData = {};
  List<String> bookNames = [];
  int currentBookIndex = 0;
  int currentChapterIndex = 0;
  List<String> chapterNumbers = [];
  late FlutterTts flutterTts;
  List<Color> recentColors = [];
  Set<String> selectedVerses = {}; // e.g., "John 3:16"
  Map<String, Color> highlightedVerses = {}; // verseKey -> color
  Color pickerColor = Colors.amber;           // The currently picked color for highlighting
OverlayEntry? _colorBarOverlay;
Map<String, String> verseNotes = {}; // Add this in your State class


void _openNotePageForVerse(String verseKey, String verseNum, String verseText) {
  TextEditingController noteController = TextEditingController(
    text: verseNotes[verseKey] ?? '',
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).canvasColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              verseKey,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Write your note here...',
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
    setState(() {
      verseNotes[verseKey] = text; // 🔥 Save note automatically
    });
  },
),
            
          ],
        ),
      );
    },
  );
}

void _onBookOrChapterChanged(int newBookIndex, int newChapterIndex) {
  setState(() {
    currentBookIndex = newBookIndex;
    currentChapterIndex = newChapterIndex;
    currentReadingVerseIndex = 0;
  });
  flutterTts.stop(); // Stop reading the old chapter
  ttsState = TtsState.stopped;
}

void _updateRecentColors(Color color) {
  recentColors.remove(color); // Remove if already there
  recentColors.insert(0, color); // Add to top
  if (recentColors.length > 5) {
    recentColors = recentColors.sublist(0, 5); // Keep only 5
  }
}
void _showColorPickerBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a highlight color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                setState(() {
                  pickerColor = color;

                  for (var verse in selectedVerses) {
                    highlightedVerses[verse] = color;
                  }
                });
              },
              pickerAreaHeightPercent: 0.4,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hueWheel,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pickerColor,
                    foregroundColor: useWhiteForeground(pickerColor) ? Colors.white : Colors.black,
                  ),
                  child: const Text('Apply'),
                  onPressed: () {
                    setState(() {
                      _updateRecentColors(pickerColor);
                      selectedVerses.clear();
                      _colorBarOverlay?.remove();
                      _colorBarOverlay = null;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}


void _showBottomLeftColorBar() {
  _colorBarOverlay?.remove();
  _colorBarOverlay = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 16,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clear highlight icon
              GestureDetector(
                onTap: () {
                  setState(() {
                    for (var verse in selectedVerses) {
                      highlightedVerses.remove(verse);
                    }
                    selectedVerses.clear();
                    _colorBarOverlay?.remove();
                    _colorBarOverlay = null;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                  child: const Icon(Icons.clear, size: 18, color: Colors.red),
                ),
              ),
              // Scrollable recent colors
              SizedBox(
                height: 36,
                width: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...recentColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            for (var verse in selectedVerses) {
                              highlightedVerses[verse] = color;
                            }
                            _updateRecentColors(color);
                            selectedVerses.clear();
                            _colorBarOverlay?.remove();
                            _colorBarOverlay = null;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }),
                    // Color Picker icon
                    GestureDetector(
                      onTap: () => _showColorPickerBottomSheet(),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade500,
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.add, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(_colorBarOverlay!);
}

Widget buildVerseTile(String verseKey, String verseNum, String verseText) {
  final isSelected = selectedVerses.contains(verseKey);
  final highlightColor = highlightedVerses[verseKey];

  return GestureDetector(
 onTap: () {
  setState(() {
    if (selectedVerses.contains(verseKey)) {
      selectedVerses.remove(verseKey);
    } else {
      selectedVerses.add(verseKey);
    }
    if (selectedVerses.isNotEmpty) {
      _showBottomLeftColorBar(); // ← Show overlay
    } else {
      _colorBarOverlay?.remove(); // ← Remove overlay if none selected
      _colorBarOverlay = null;
    }
  });
},

    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verseNum,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Stack(
              children: [
             Padding(
  padding: const EdgeInsets.only(bottom: 2.0),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Text.rich(
          TextSpan(
            text: verseText,
            style: TextStyle(
              fontSize: 18,
              height: 1.4,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              backgroundColor: highlightColor?.withOpacity(0.4),
            ),
          ),
        ),
      ),
      if (isSelected)
        GestureDetector(
          onTap: () {
            _openNotePageForVerse(verseKey, verseNum, verseText);
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(
              Icons.edit_note,
              size: 20,
              color: verseNotes.containsKey(verseKey) ? Colors.blue : Colors.grey,
            ),
          ),
        ),
    ],
  ),
),

                if (isSelected)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 2,
                      decoration: DottedDecoration(
                        shape: Shape.line,
                        color: Colors.grey.shade400,
                        linePosition: LinePosition.bottom,
                        dash: [3, 3],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


@override
void initState() {
  super.initState();
  flutterTts = FlutterTts();
  flutterTts.setLanguage("en-US");
  flutterTts.setPitch(1.0);

flutterTts.setStartHandler(() {
  setState(() => ttsState = TtsState.playing);
});
flutterTts.setCompletionHandler(() {
  setState(() {
    ttsState = TtsState.stopped;
    currentReadingVerseIndex = null;
  });
});
flutterTts.setProgressHandler((text, start, end, word) {
    setState(() {
      // Estimate current verse index based on what is being spoken
      final book = bookNames[currentBookIndex];
      final chapter = chapterNumbers[currentChapterIndex];
      final verses = bibleData[book]?[chapter] ?? {};
      final verseNumbers = verses.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      for (int i = 0; i < verseNumbers.length; i++) {
        final verseText = verses[verseNumbers[i]].toString();
        if (verseText.contains(word)) {
          currentReadingVerseIndex = i;
          break;
        }
      }
    });
  });
flutterTts.setPauseHandler(() {
  setState(() {
    ttsState = TtsState.paused;
  });
});
flutterTts.setCancelHandler(() {
  setState(() {
    ttsState = TtsState.stopped;
  });
});

flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
  final String book = bookNames[currentBookIndex];
  final String chapter = chapterNumbers[currentChapterIndex];
  final Map<String, dynamic> verses = bibleData[book][chapter];
  final verseNumbers = verses.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

  int cumulativeLength = 0;
  for (int i = 0; i < verseNumbers.length; i++) {
    final verseText = verses[verseNumbers[i]].toString();
    cumulativeLength += verseText.length + 1;
    if (startOffset < cumulativeLength) {
      setState(() {
        currentReadingVerseIndex = i;
      });
      return;
    }
  }
});


  loadBible();
}


  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BibleChapterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bibleVersion != widget.bibleVersion) {
      loadBible();
    }
  }

  Future<void> loadBible() async {
    final String jsonString = await rootBundle.loadString(
        'assets/data/${widget.bibleVersion}_bible.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);

    setState(() {
      bibleData = data;
      bookNames = data.keys.toList();
      currentBookIndex = 0;
      chapterNumbers = (data[bookNames[0]] as Map<String, dynamic>)
          .keys
          .toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      currentChapterIndex = 0;
    });
  }

  void goToNextChapter() {
    setState(() {
      if (currentChapterIndex < chapterNumbers.length - 1) {
        currentChapterIndex++;
      } else if (currentBookIndex < bookNames.length - 1) {
        currentBookIndex++;
        chapterNumbers = (bibleData[bookNames[currentBookIndex]] as Map<String, dynamic>)
            .keys
            .toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        currentChapterIndex = 0;
      }
     // Reset TTS state and progress
    ttsState = TtsState.stopped;
    currentReadingVerseIndex = null;
    _stopTts(); 
    });
  }

  void goToPreviousChapter() {
    setState(() {
      if (currentChapterIndex > 0) {
        currentChapterIndex--;
      } else if (currentBookIndex > 0) {
        currentBookIndex--;
        chapterNumbers = (bibleData[bookNames[currentBookIndex]] as Map<String, dynamic>)
            .keys
            .toList()
          ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        currentChapterIndex = chapterNumbers.length - 1;
      }
    // Reset TTS state and progress
    ttsState = TtsState.stopped;
    currentReadingVerseIndex = null;
    _stopTts();
    });
  }


  void _showBookPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        int? expandedBookIndex;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: ListView.separated(
                itemCount: bookNames.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final isCurrentBook = index == currentBookIndex;
                  final chapters = (bibleData[bookNames[index]] as Map<String, dynamic>)
                      .keys
                      .toList()
                    ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          bookNames[index],
                          style: TextStyle(
                            fontWeight: isCurrentBook ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentBook
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        tileColor: isCurrentBook
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : null,
                        trailing: Icon(
                          expandedBookIndex == index
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          setSheetState(() {
                            expandedBookIndex = expandedBookIndex == index ? null : index;
                          });
                        },
                      ),
                      if (expandedBookIndex == index)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: chapters.map<Widget>((chapterNum) {
                              final isCurrentChapter =
                                  isCurrentBook && chapterNum == chapterNumbers[currentChapterIndex];
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCurrentChapter
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surface,
                                  foregroundColor: isCurrentChapter
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
                                  minimumSize: const Size(40, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                 
  // First update the chapterNumbers list so it's in sync
  chapterNumbers = chapters;

  // Then update book/chapter safely via your helper
  _onBookOrChapterChanged(index, chapters.indexOf(chapterNum));
                                },
                                child: Text(chapterNum),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

Widget buildChapterParagraph(Map<String, dynamic> verses) {
  final verseNumbers = verses.keys.toList()
    ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

  final String book = bookNames[currentBookIndex];
  final String chapter = chapterNumbers[currentChapterIndex];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: verseNumbers.map((vNum) {
      final verseKey = "$book:$chapter:$vNum";
      return buildVerseTile(verseKey, vNum, verses[vNum].toString());
    }).toList(),
  );
}


Future<void> _speakCurrentChapter({int fromVerse = 0}) async {
  if (bibleData.isEmpty) return;
  final String book = bookNames[currentBookIndex];
  final String chapter = chapterNumbers[currentChapterIndex];
  final Map<String, dynamic> verses = bibleData[book][chapter];
  final verseNumbers = verses.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  final textToRead = verseNumbers
      .sublist(fromVerse)
      .map((v) => verses[v])
      .join(' ');
  await flutterTts.speak('$book chapter $chapter. $textToRead');
  setState(() {
    ttsState = TtsState.playing;
    currentReadingVerseIndex = fromVerse;
  });
}



  @override
  Widget build(BuildContext context) {
    if (bibleData.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String book = bookNames[currentBookIndex];
    final String chapter = chapterNumbers[currentChapterIndex];
    final Map<String, dynamic> verses = bibleData[book][chapter];

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showBookPicker(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$book $chapter', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        actions: [
IconButton(
  icon: Icon(
    ttsState == TtsState.playing ? Icons.pause :
    ttsState == TtsState.paused ? Icons.play_arrow : Icons.volume_up,
  ),
  tooltip: ttsState == TtsState.playing ? 'Pause' :
           ttsState == TtsState.paused ? 'Resume' : 'Read Aloud',
  onPressed: () async {
    if (ttsState == TtsState.playing) {
      await flutterTts.pause();
    } else if (ttsState == TtsState.paused) {
      // On iOS/web, you can try flutterTts.resume() if supported.
      // On Android, just restart from the current verse.
      if (currentReadingVerseIndex != null) {
        await _speakCurrentChapter(fromVerse: currentReadingVerseIndex!);
      } else {
        await _speakCurrentChapter();
      }
      setState(() {
        isPaused = false;
      });
    } else {
      await _speakCurrentChapter();
    }
  },
),



          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Select Bible Version',
            onSelected: widget.onSelectVersion,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ESV', child: Text('ESV')),
              const PopupMenuItem(value: 'NIV', child: Text('NIV')),
            ],
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            tooltip: 'Toggle Dark/Light Mode',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
body: Stack(
  children: [
    // Main scrolling content
    SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: buildChapterParagraph(verses),
    ),

    // Floating navigation buttons
    Positioned(
      bottom: 50,
      left: 20,
      child: ElevatedButton(
        onPressed: goToPreviousChapter,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: const Icon(Icons.arrow_back, size: 24),
      ),
    ),
    Positioned(
      bottom: 50,
      right: 20,
      child: ElevatedButton(
        onPressed: goToNextChapter,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: const Icon(Icons.arrow_forward, size: 24),
      ),
    ),

    // Bottom color picker bar
    if (selectedVerses.isNotEmpty)
      Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
          //  child: Container(
           //   height: 50, // Adjust height for visibility
          //    color: Colors.grey.withOpacity(0.3), // Placeholder color
           //   child: const Center(child: Text("Color Picker Bar")),
          //  ),
          ),
        ),
      ),
  ],
),


    );
  }
}