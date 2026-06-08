import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MindDumpsApp());
}

class MindDumpsApp extends StatelessWidget {
  const MindDumpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorSchemeSeed: const Color(0xFFFFFFFF),
        fontFamily: 'Courier',
      ),
      home: const MainGate(),
    );
  }
}

class MainGate extends StatefulWidget {
  const MainGate({super.key});

  @override
  State<MainGate> createState() => _MainGateState();
}

class _MainGateState extends State<MainGate> {
  bool _loading = true;
  String? _username;

  @override
  void initState() {
    super.initState();
    _checkIdentity();
  }

  Future<void> _checkIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('user_name');
      _loading = false;
    });
  }

  void _onNameSaved(String name) {
    setState(() {
      _username = name;
    });
  }

  void _onIdentityWiped() {
    setState(() {
      _username = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_username == null) {
      return OnboardingScreen(onSave: _onNameSaved);
    }

    return DashboardScreen(
      username: _username!,
      onWiped: _onIdentityWiped,
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  final Function(String) onSave;
  const OnboardingScreen({super.key, required this.onSave});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    widget.onSave(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Who is polluting this local storage?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Give us a name. Any name.',
                hintStyle: TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class DashboardScreen extends StatefulWidget {
  final String username;
  final VoidCallback onWiped;

  const DashboardScreen({
    super.key,
    required this.username,
    required this.onWiped,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _allDumps = [];
  List<Map<String, dynamic>> _filteredDumps = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilterMood = 'All';

  @override
  void initState() {
    super.initState();
    _loadDumps();
  }

  Future<void> _loadDumps() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('mind_dumps_data');
    if (data != null) {
      setState(() {
        _allDumps = List<Map<String, dynamic>>.from(json.decode(data));
        _applyFilters();
      });
    } else {
      setState(() {
        _allDumps = [];
        _filteredDumps = [];
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredDumps = _allDumps.where((dump) {
        final matchesSearch = dump['content'].toString().toLowerCase().contains(query);
        final matchesMood = _selectedFilterMood == 'All' || dump['mood'] == _selectedFilterMood;
        return matchesSearch && matchesMood;
      }).toList();
    });
  }

  Future<void> _deleteDump(int index) async {
    final actualIndex = _allDumps.indexOf(_filteredDumps[index]);
    if (actualIndex != -1) {
      setState(() {
        _allDumps.removeAt(actualIndex);
        _applyFilters();
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mind_dumps_data', json.encode(_allDumps));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${widget.username}.',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "How's your day? ;)",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white54),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, anim, secondaryAnim) => SettingsScreen(
                            onWiped: widget.onWiped,
                            onDumpsCleared: _loadDumps,
                          ),
                          transitionsBuilder: (context, anim, secondaryAnim, child) {
                            return FadeTransition(opacity: anim, child: child);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search through past trauma...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white38),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['All', 'Anxious', 'Numb', 'Chaos', 'Chill', 'Rage'].map((mood) {
                    final isSelected = _selectedFilterMood == mood;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(mood),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilterMood = mood;
                              _applyFilters();
                            });
                          }
                        },
                        selectedColor: Colors.white,
                        backgroundColor: const Color(0xFF121212),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white54,
                          fontSize: 12,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: isSelected ? Colors.white : Colors.white10),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _filteredDumps.isEmpty
                    ? const Center(
                        child: Text(
                          'Nothing found.\nEither you are cured or filters are tight.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white12, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredDumps.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final dump = _filteredDumps[index];
                          return Dismissible(
                            key: Key(dump['date']! + index.toString() + _selectedFilterMood),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _deleteDump(index),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            ),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF121212),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dump['date']!,
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          dump['mood'] ?? 'Unknown',
                                          style: const TextStyle(color: Colors.white60, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    dump['content']!,
                                    style: const TextStyle(color: Colors.white87, fontSize: 14, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        onPressed: () async {
          final result = await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, anim, secondaryAnim) => const DumpStationScreen(),
              transitionsBuilder: (context, anim, secondaryAnim, child) {
                return FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                      CurveTween(curve: Curves.fastOutSlowIn).animate(anim),
                    ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
          if (result == true) {
            _loadDumps();
          }
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class DumpStationScreen extends StatefulWidget {
  const DumpStationScreen({super.key});

  @override
  State<DumpStationScreen> createState() => _DumpStationScreenState();
}

class _DumpStationScreenState extends State<DumpStationScreen> {
  final TextEditingController _controller = TextEditingController();
  String _selectedMood = 'Chill';
  int _wordCount = 0;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateStats);
  }

  void _updateStats() {
    final text = _controller.text.trim();
    setState(() {
      _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
      _charCount = text.length;
    });
  }

  Future<void> _buryIt() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('mind_dumps_data');
    List<dynamic> dumps = [];

    if (data != null) {
      dumps = json.decode(data);
    }

    final now = DateTime.now();
    final formattedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    dumps.insert(0, {
      'date': formattedDate,
      'content': text,
      'mood': _selectedMood,
    });

    await prefs.setString('mind_dumps_data', json.encode(dumps));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _buryIt,
            child: const Text(
              'Bury it',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select current head state:',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['Chill', 'Anxious', 'Numb', 'Chaos', 'Rage'].map((mood) {
                  final isSelected = _selectedMood == mood;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(mood),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedMood = mood);
                        }
                      },
                      selectedColor: Colors.white,
                      backgroundColor: const Color(0xFF121212),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white54,
                        fontSize: 12,
                      ),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: isSelected ? Colors.white : Colors.white10),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'What is polluting your mind right now?',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Words: $_wordCount | Chars: $_charCount',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  Text(
                    _wordCount > 30 ? 'Vent mode active.' : 'Keep spilling.',
                    style: const TextStyle(color: Colors.white12, fontSize: 11),
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
  void dispose() {
    _controller.removeListener(_updateStats);
    _controller.dispose();
    super.dispose();
  }
}

class SettingsScreen extends StatelessWidget {
  final VoidCallback onWiped;
  final VoidCallback onDumpsCleared;

  const SettingsScreen({
    super.key,
    required this.onWiped,
    required this.onDumpsCleared,
  });

  Future<void> _wipeIdentity(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    onWiped();
    Navigator.of(context).pop();
  }

  Future<void> _clearDumps(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mind_dumps_data');
    onDumpsCleared();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF121212),
        content: Text('All records incinerated.', style: TextStyle(color: Colors.white, fontFamily: 'Courier')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('settings.', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wipe Identity', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              subtitle: const Text('Clears saved name from local storage.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onTap: () => _wipeIdentity(context),
            ),
            const Divider(color: Colors.white10, height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Incinerate All Dumps', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              subtitle: const Text('Permanently deletes every single record. No undo.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: const Icon(Icons.local_fire_department, color: Colors.redAccent),
              onTap: () => _clearDumps(context),
            ),
          ],
        ),
      ),
    );
  }
}
