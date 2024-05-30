import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>[];
  var history = <WordPair>[];
  GlobalKey? historyListKey;

  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    current = WordPair.random();
    notifyListeners();
  }

  void toggleFavorite(WordPair pair) {
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  void remove(WordPair favorite) {
    favorites.remove(favorite);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    Widget page;

    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      default:
        throw UnimplementedError('no widget for page selection $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200) ,
        child: page,)
        ,);
        
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: false,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite),
                  label: Text('Favorites'),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: page,
            ),
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    //use the apps theme
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimary);

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: pair.asPascalCase,
        ),
      ),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(),
          ),
          SizedBox(
            height: 10,
          ),
          BigCard(pair: pair),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite(appState.current);
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
          Spacer(flex: 2)
        ],
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimary);
    //var iconData = Icons.clear;

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text("No favorites yet"),
      );
    }

    return ListView(
      children: [
        Text(
          'Favorites:',
          style: style,
        ),
        for (var favorite in appState.favorites)
          ListTile(
            leading: Icon(Icons.delete),
            title: Text(favorite.asLowerCase),
            onTap: () {
              appState.remove(favorite);
            },
          ),
      ],
    );
  }
}

class HistoryListView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HistoryListViewState();
  }
}

class _HistoryListViewState extends State<HistoryListView> {
  final _key = GlobalKey();
  static const Gradient _maskingGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black],
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
        shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: AnimatedList(
            key: _key,
            reverse: true,
            padding: EdgeInsets.only(top: 100),
            initialItemCount: appState.history.length,
            itemBuilder: (context, index, animation) {
              final pair = appState.history[index];
              return SizeTransition(
                  sizeFactor: animation,
                  child: Center(
                      child: TextButton.icon(
                          onPressed: () {
                            appState.toggleFavorite(pair);
                          },
                          icon: appState.favorites.contains(pair)
                              ? Icon(Icons.favorite, size: 12)
                              : SizedBox(),
                          label: Text(
                            pair.asLowerCase,
                            semanticsLabel: pair.asPascalCase,
                          ))));
            }));
  }
}
