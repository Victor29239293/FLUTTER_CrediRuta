import 'package:cobrador_app/presentation/screens/home_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/home/0',
  routes: [
    GoRoute(
      path: '/home/:page',
      name: HomeScreen.name,
      builder: (context, state) {
        final pageIndex = int.parse(state.pathParameters['page'] ?? '0');
        if (pageIndex < 0 || pageIndex > 2) {
          return HomeScreen(pageIndex: 0);
        }
        return HomeScreen(pageIndex: pageIndex);
      },
    ),
    GoRoute(path: '/', redirect: (_, _) => '/home/0'),
  ],
);
