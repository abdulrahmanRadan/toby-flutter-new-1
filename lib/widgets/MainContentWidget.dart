// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toby_flutter/providers/app_state.dart';
import 'package:toby_flutter/screens/EditCollectionScreen.dart';
import 'package:toby_flutter/screens/Tabs_screen.dart';
import 'package:toby_flutter/screens/add_collection.dart';
import 'package:toby_flutter/services/CollectionService.dart';
import 'package:toby_flutter/widgets/CollectionSectionWidget.dart';
import 'package:toby_flutter/widgets/FooterWidget.dart';
import 'package:toby_flutter/widgets/HeaderWidget.dart';

class MainContentWidget extends StatefulWidget {
  const MainContentWidget({super.key});

  @override
  _MainContentWidgetState createState() => _MainContentWidgetState();
}

class _MainContentWidgetState extends State<MainContentWidget> {
  late final CollectionService apiService;
  late Future<List<dynamic>> collectionsFuture;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    apiService = CollectionService(appState);
    collectionsFuture = fetchCollections();
  }

  Future<List<dynamic>> fetchCollections() async {
    try {
      return await apiService.fetchCollections();
    } catch (e) {
      debugPrint("Error fetching collections: $e");
      return [];
    }
  }

  void _refreshCollections() {
    setState(() {
      collectionsFuture = fetchCollections();
    });
  }

  // حذف مجموعة
  void _deleteCollection(int id) async {
    try {
      await apiService.deleteCollection(id);
      _refreshCollections();
    } catch (e) {
      debugPrint("Error deleting collection: $e");
    }
  }

  // تحديث مجموعة
// تحديث مجموعة
  void _updateCollection(int id, String title, String description) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateCollectionState(collection: {
          'id': id,
          'title': title,
          'description': description,
        }),
      ),
    ).then((result) {
      if (result == true) {
        _refreshCollections(); // تحديث البيانات بعد التعديل
      }
    });
  }

// الانتقال إلى صفحة التبويبات مع التحديث عند العودة
  void _navigateToTabs(int collectionId, List<dynamic> tabs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TabsPage(
          collectionId: collectionId,
          tabs: tabs,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshCollections(); // تحديث البيانات بعد الحذف
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: HeaderWidget(
        title: 'My Collections',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCollections,
          ),
        ],
      ),
      body: SafeArea(
        child: SizedBox(
          height: screenHeight,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<dynamic>>(
                  future: collectionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      List<dynamic> collections = snapshot.data!;
                      return CollectionSectionWidget(
                        cardsData: collections.map((collection) {
                          List<dynamic> tags = collection['tags'] ?? [];
                          List<dynamic> tabs = collection['tabs'] ?? [];
                          return {
                            'id': collection['id'],
                            'title': collection['title'] ?? 'Untitled',
                            'subtitle':
                                collection['description'] ?? 'No description',
                            'tags': tags,
                            'tabs': tabs,
                            'icon': Icons.folder,
                            'color': Colors.blue,
                          };
                        }).toList(),
                        onDelete: _deleteCollection,
                        onUpdate: _updateCollection,
                        // عند الضغط على التبويب
                        onViewTabs: _navigateToTabs,
                      );
                    } else {
                      return const Center(child: Text('No collections found'));
                    }
                  },
                ),
                FooterWidget(
                  onAddPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCollectionScreen(
                          collection: const {},
                        ),
                      ),
                    );
                    _refreshCollections(); // تحديث الصفحة إذا تم إنشاء مجموعة جديدة
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
