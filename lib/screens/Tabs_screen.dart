// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toby_flutter/providers/app_state.dart';
import 'package:toby_flutter/screens/web_view_page.dart';
import 'package:toby_flutter/services/TabService.dart';

class TabsPage extends StatelessWidget {
  final List<dynamic>? tabs; // Allow null
  final int collectionId;

  const TabsPage({super.key, required this.tabs, required this.collectionId});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    late TabService apiService;
    apiService = TabService(appState);

    return DefaultTabController(
      length: tabs?.length ?? 0, // Set the number of tabs, default to 0 if null
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tabs'),
          bottom: tabs != null && tabs!.isNotEmpty
              ? PreferredSize(
                  preferredSize: Size.fromHeight(kToolbarHeight),
                  child: Row(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabs: tabs!.map((tab) {
                          return Tab(
                            text: tab['title'],
                          );
                        }).toList(),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _showAddTabDialog(context, apiService);
                        },
                        child: const Text('Add Tab'),
                      ),
                    ],
                  ),
                )
              : null, // No TabBar if there are no tabs
        ),
        body: tabs != null && tabs!.isNotEmpty
            ? TabBarView(
                children: tabs!.map((tab) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to another screen based on the URL
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WebViewPage(url: tab['url']),
                              ),
                            );
                          },
                          child: Text('Go to ${tab['title']}'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _confirmDeleteTab(
                                context, tab['id'], apiService, appState);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.red, // Red color for delete button
                          ),
                          child: const Text('Delete Tab'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No tabs available',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _showAddTabDialog(context, apiService);
                      },
                      child: const Text('Add Tab'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String formatUrl(String inputUrl) {
    String formattedUrl = inputUrl.trim();

    // Add 'https://' if not present
    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://' + formattedUrl;
    }

    // Add 'www.' if not present
    if (!formattedUrl.contains('www.')) {
      Uri uri = Uri.parse(formattedUrl);
      formattedUrl = formattedUrl.replaceFirst(uri.host, 'www.' + uri.host);
    }

    return formattedUrl;
  }

  // Pop-up dialog to add a new tab with title and URL fields
  void _showAddTabDialog(BuildContext context, TabService apiService) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Tab'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tab Title'),
              ),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Tab URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the popup
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Handle adding the new tab
                String title = titleController.text;
                String url = formatUrl(urlController.text);

                if (title.isNotEmpty && url.isNotEmpty) {
                  final result = await apiService.createTab(
                    titleController.text,
                    urlController.text,
                    collectionId,
                  );

                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tab created successfully'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Failed to create tab: ${result['message']}'),
                      ),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add Tab'),
            ),
          ],
        );
      },
    );
  }

  // Confirm dialog to delete a tab
  void _confirmDeleteTab(BuildContext context, int tabId, TabService apiService,
      AppState appState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this tab?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the popup
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final success =
                    await appState.deleteTabFromApi(tabId, apiService);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tab deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context,
                      true); // Close the TabsPage and pass true to indicate successful deletion
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete tab'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                Navigator.of(context).pop(); // Close the popup
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
