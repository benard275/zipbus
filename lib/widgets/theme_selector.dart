import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeSelector extends StatelessWidget {
  final bool showAsBottomSheet;
  final bool showTitle;

  const ThemeSelector({
    super.key,
    this.showAsBottomSheet = false,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final themeService = ThemeService();
        final currentTheme = themeService.themeMode;

        if (showAsBottomSheet) {
          return _buildBottomSheetContent(context, themeService, currentTheme);
        } else {
          return _buildInlineContent(context, themeService, currentTheme);
        }
      },
    );
  }

  Widget _buildBottomSheetContent(BuildContext context, ThemeService themeService, AppThemeMode currentTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              const Text(
                'Choose Theme',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...AppThemeMode.values.map((mode) => _buildThemeOption(
            context,
            themeService,
            mode,
            currentTheme,
            isBottomSheet: true,
          )),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInlineContent(BuildContext context, ThemeService themeService, AppThemeMode currentTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          const Text(
            'Theme',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...AppThemeMode.values.map((mode) => _buildThemeOption(
          context,
          themeService,
          mode,
          currentTheme,
          isBottomSheet: false,
        )),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeService themeService,
    AppThemeMode mode,
    AppThemeMode currentTheme, {
    required bool isBottomSheet,
  }) {
    final isSelected = mode == currentTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          await themeService.setThemeMode(mode);
          if (isBottomSheet && context.mounted) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                themeService.getThemeModeIcon(mode),
                color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Theme.of(context).iconTheme.color,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      themeService.getThemeModeDisplayName(mode),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : null,
                      ),
                    ),
                    Text(
                      _getThemeDescription(mode),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow system settings';
    }
  }

  /// Show theme selector as bottom sheet
  static void showThemeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ThemeSelector(showAsBottomSheet: true),
    );
  }
}

/// Theme toggle button for app bars
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final themeService = ThemeService();
        final currentTheme = themeService.themeMode;
        
        return IconButton(
          icon: Icon(themeService.getThemeModeIcon(currentTheme)),
          tooltip: 'Change Theme',
          onPressed: () => ThemeSelector.showThemeBottomSheet(context),
        );
      },
    );
  }
}

/// Quick theme switch button (cycles through themes)
class QuickThemeSwitch extends StatelessWidget {
  const QuickThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final themeService = ThemeService();
        final currentTheme = themeService.themeMode;
        
        return IconButton(
          icon: Icon(themeService.getThemeModeIcon(currentTheme)),
          tooltip: themeService.getThemeModeDisplayName(currentTheme),
          onPressed: () async {
            // Cycle through themes: system -> light -> dark -> system
            AppThemeMode nextTheme;
            switch (currentTheme) {
              case AppThemeMode.system:
                nextTheme = AppThemeMode.light;
                break;
              case AppThemeMode.light:
                nextTheme = AppThemeMode.dark;
                break;
              case AppThemeMode.dark:
                nextTheme = AppThemeMode.system;
                break;
            }
            
            await themeService.setThemeMode(nextTheme);
            
            // Show feedback
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        themeService.getThemeModeIcon(nextTheme),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(themeService.getThemeModeDisplayName(nextTheme)),
                    ],
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        );
      },
    );
  }
}
