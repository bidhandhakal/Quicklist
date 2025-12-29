import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/routes.dart'; // import already exists, just ensuring order or adding if missing? Wait, routes is on line 5.
import '../../controllers/task_controller.dart';
import '../../data/dummy_categories.dart';
import 'package:provider/provider.dart';
import '../widgets/task_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.home),
        ),
        title: const Text('Categories'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<TaskController>(
              builder: (context, taskController, child) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount:
                      DummyCategories.categories.length + 1, // +1 for native ad
                  itemBuilder: (context, index) {
                    // Show native ad after 3rd category
                    if (index == 3) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: NativeAdWidget(
                          screenId: 'category_screen_category_list',
                        ),
                      );
                    }

                    // Adjust index for categories after ad
                    final categoryIndex = index > 3 ? index - 1 : index;
                    final category = DummyCategories.categories[categoryIndex];
                    final categoryTasks = taskController.getTasksByCategory(
                      category.id,
                    );
                    final taskCount = categoryTasks.length;
                    final completedCount = categoryTasks
                        .where((t) => t.isCompleted)
                        .length;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CategoryDetailScreen(category: category),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Category icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: category.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  category.icon,
                                  color: category.color,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Category info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$taskCount task${taskCount != 1 ? 's' : ''}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),

                              // Progress indicator
                              if (taskCount > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$completedCount/$taskCount',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: category.color,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 60,
                                      child: LinearProgressIndicator(
                                        value: completedCount / taskCount,
                                        backgroundColor: category.color
                                            .withValues(alpha: 0.2),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              category.color,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Banner ad at bottom
          const BannerAdWidget(screenId: 'category'),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final TaskCategory category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: category.color),
            const SizedBox(width: 8),
            Text(category.name),
          ],
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<TaskController>(
              builder: (context, taskController, child) {
                final tasks = taskController.getTasksByCategory(category.id);

                if (tasks.isEmpty) {
                  return EmptyState(
                    icon: category.icon,
                    title: 'No ${category.name} Tasks',
                    message: 'Add tasks to this category to see them here',
                    action: FilledButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.addTask);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task'),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: tasks.length + 1, // +1 for native ad
                  itemBuilder: (context, index) {
                    // Show native ad after 4th task
                    if (index == 4 && tasks.length > 4) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: NativeAdWidget(
                          screenId: 'category_screen_task_list',
                        ),
                      );
                    }

                    // Adjust index for tasks after ad
                    final taskIndex = index > 4 ? index - 1 : index;
                    if (taskIndex >= tasks.length) {
                      return const SizedBox.shrink();
                    }

                    return TaskTile(
                      task: tasks[taskIndex],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.editTask,
                          arguments: tasks[taskIndex].id,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Banner Ad at bottom
          const BannerAdWidget(screenId: 'category_screen'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.addTask);
        },
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
