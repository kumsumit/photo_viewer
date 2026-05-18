import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_viewer/photo_viewer.dart';

void main() {
  testWidgets('showPhotoViewer opens and the default close button pops it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                unawaited(
                  showPhotoViewer(
                    context: context,
                    builder: (_) => const Text('viewer content'),
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('viewer content'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('viewer content'), findsNothing);
  });

  testWidgets('onJumpToPage animates to a valid page', (tester) async {
    late PhotoViewerPageJump jumpToPage;

    await tester.pumpWidget(
      MaterialApp(
        home: PhotoViewerScreen(
          builders: [
            (_) => const _PageBuilder(text: 'page 0'),
            (_) => const _PageBuilder(text: 'page 1'),
          ],
          onJumpToPage: (jump) {
            jumpToPage = jump;
          },
          showDefaultCloseButton: false,
        ),
      ),
    );

    expect(find.text('page 0'), findsOneWidget);

    jumpToPage(1);
    await tester.pumpAndSettle();

    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('VerticalSwipeDismissible dismisses after a vertical drag', (
    tester,
  ) async {
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 400,
          child: VerticalSwipeDismissible(
            dismissThreshold: 0.1,
            onDismissed: () {
              dismissed = true;
            },
            child: const SizedBox.expand(key: ValueKey('dismissible-child')),
          ),
        ),
      ),
    );

    await tester.dragFrom(const Offset(200, 200), const Offset(0, 240));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });

  testWidgets('VerticalSwipeDismissible ignores horizontal swipes', (
    tester,
  ) async {
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 400,
          child: VerticalSwipeDismissible(
            onDismissed: () {
              dismissed = true;
            },
            child: const SizedBox.expand(key: ValueKey('dismissible-child')),
          ),
        ),
      ),
    );

    await tester.dragFrom(const Offset(200, 200), const Offset(220, 0));
    await tester.pumpAndSettle();

    expect(dismissed, isFalse);
  });

  testWidgets('InteractivePhotoPage reports max scale after double tap', (
    tester,
  ) async {
    final transformationController = TransformationController();
    late final AnimationController animationController;
    late final AnimationController controlsVisibilityController;
    final scales = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: _AnimationControllerHost(
          builder: (context, vsync) {
            animationController = AnimationController(
              vsync: vsync,
              duration: const Duration(milliseconds: 300),
            );
            controlsVisibilityController = AnimationController(
              value: 1,
              vsync: vsync,
              duration: const Duration(milliseconds: 100),
            );

            return InteractivePhotoPage(
              transformationController: transformationController,
              animationController: animationController,
              controlsVisibilityController: controlsVisibilityController,
              minScale: 1,
              maxScale: 2,
              onDismiss: () {},
              isScrolling: false,
              heroTag: '',
              useHero: false,
              onScaleChanged: scales.add,
              builder: (_) => Container(
                key: const ValueKey('photo-page-child'),
                width: 200,
                height: 200,
                color: Colors.transparent,
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('photo-page-child')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('photo-page-child')));
    await tester.pumpAndSettle();

    expect(scales, contains(2));

    transformationController.dispose();
    animationController.dispose();
    controlsVisibilityController.dispose();
  });

  test('PhotoViewerMultipleImage validates the initial index', () {
    expect(
      () => PhotoViewerMultipleImage(
        imageUrls: const ['asset.png'],
        index: 2,
        id: 'gallery',
      ),
      throwsAssertionError,
    );
  });
}

class _PageBuilder extends StatelessWidget {
  const _PageBuilder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}

class _AnimationControllerHost extends StatefulWidget {
  const _AnimationControllerHost({required this.builder});

  final Widget Function(BuildContext context, TickerProvider vsync) builder;

  @override
  State<_AnimationControllerHost> createState() =>
      _AnimationControllerHostState();
}

class _AnimationControllerHostState extends State<_AnimationControllerHost>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) => widget.builder(context, this);
}
