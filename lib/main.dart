import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:divvy/core/constants/app_constants.dart';
import 'package:divvy/core/theme/app_theme.dart';
import 'package:divvy/core/network/api_client.dart';
import 'package:divvy/core/network/network_info.dart';
import 'package:divvy/core/storage/secure_storage.dart';
import 'package:divvy/core/storage/database_helper.dart';
import 'package:divvy/core/services/services.dart';
import 'package:divvy/core/config/environment.dart';
import 'package:divvy/data/datasources/local/local_datasources.dart' as local;
import 'package:divvy/data/datasources/remote/remote_datasources.dart'
    as remote;
import 'package:divvy/data/repositories/repositories.dart';
import 'package:divvy/presentation/viewmodels/viewmodels.dart';
import 'package:divvy/presentation/views/auth/auth_views.dart';
import 'package:divvy/presentation/views/groups/group_views.dart';
import 'package:divvy/presentation/views/bills/bill_views.dart';
import 'package:divvy/presentation/views/transactions/transaction_views.dart';
import 'package:divvy/presentation/widgets/widgets.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase FIRST before any Firebase services
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize core services
  final secureStorage = SecureStorage();
  final databaseHelper = DatabaseHelper.instance;
  await databaseHelper.database; // Initialize database

  final apiClient = ApiClient(
    baseUrl: EnvironmentConfig.apiBaseUrl,
    secureStorage: secureStorage,
  );

  final networkInfo = NetworkInfo();

  // Initialize notification service (after Firebase initialization)
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize local data sources
  final userLocalDataSource = local.UserLocalDataSource(databaseHelper);
  final groupLocalDataSource = local.GroupLocalDataSource(databaseHelper);
  final billLocalDataSource = local.BillLocalDataSource(databaseHelper);
  final transactionLocalDataSource = local.TransactionLocalDataSource(
    databaseHelper,
  );
  final syncQueueLocalDataSource = local.SyncQueueLocalDataSource(
    databaseHelper,
  );

  // Initialize remote data sources
  final authRemoteDataSource = remote.AuthRemoteDataSource(
    apiClient: apiClient,
  );
  final groupRemoteDataSource = remote.GroupRemoteDataSource(
    apiClient: apiClient,
  );
  final billRemoteDataSource = remote.BillRemoteDataSource(
    apiClient: apiClient,
  );
  final paymentRemoteDataSource = remote.PaymentRemoteDataSource(
    apiClient: apiClient,
  );
  final transactionRemoteDataSource = remote.TransactionRemoteDataSource(
    apiClient: apiClient,
  );
  final syncRemoteDataSource = remote.SyncRemoteDataSource(
    apiClient: apiClient,
  );

  // Initialize repositories
  final authRepository = AuthRepository(
    remoteDataSource: authRemoteDataSource,
    localDataSource: userLocalDataSource,
    secureStorage: secureStorage,
  );

  final groupRepository = GroupRepository(
    remoteDataSource: groupRemoteDataSource,
    localDataSource: groupLocalDataSource,
    syncQueueDataSource: syncQueueLocalDataSource,
    networkInfo: networkInfo,
  );

  final billRepository = BillRepository(
    remoteDataSource: billRemoteDataSource,
    localDataSource: billLocalDataSource,
    syncQueueDataSource: syncQueueLocalDataSource,
    networkInfo: networkInfo,
  );

  final paymentRepository = PaymentRepository(
    remoteDataSource: paymentRemoteDataSource,
    networkInfo: networkInfo,
  );

  final transactionRepository = TransactionRepository(
    remoteDataSource: transactionRemoteDataSource,
    localDataSource: transactionLocalDataSource,
    networkInfo: networkInfo,
  );

  // Initialize sync service
  final syncService = SyncService(
    syncQueueDataSource: syncQueueLocalDataSource,
    syncRemoteDataSource: syncRemoteDataSource,
    groupRepository: groupRepository,
    billRepository: billRepository,
    transactionRepository: transactionRepository,
    networkInfo: networkInfo,
  );

  runApp(
    MyApp(
      authRepository: authRepository,
      groupRepository: groupRepository,
      billRepository: billRepository,
      paymentRepository: paymentRepository,
      transactionRepository: transactionRepository,
      syncService: syncService,
      networkInfo: networkInfo,
      syncQueueLocalDataSource: syncQueueLocalDataSource,
      notificationService: notificationService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final GroupRepository groupRepository;
  final BillRepository billRepository;
  final PaymentRepository paymentRepository;
  final TransactionRepository transactionRepository;
  final SyncService syncService;
  final NetworkInfo networkInfo;
  final local.SyncQueueLocalDataSource syncQueueLocalDataSource;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.groupRepository,
    required this.billRepository,
    required this.paymentRepository,
    required this.transactionRepository,
    required this.syncService,
    required this.networkInfo,
    required this.syncQueueLocalDataSource,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            repository: authRepository,
            notificationService: notificationService,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => GroupViewModel(repository: groupRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => BillViewModel(repository: billRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => PaymentViewModel(
            paymentRepository: paymentRepository,
            billRepository: billRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              TransactionViewModel(repository: transactionRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncViewModel(
            syncService: syncService,
            networkInfo: networkInfo,
            syncQueueDataSource: syncQueueLocalDataSource,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const AuthenticationWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (authViewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authViewModel.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Bottom navigation tabs
  static const List<Widget> _screens = [
    GroupsListScreen(),
    BillsListScreen(),
    TransactionsListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          const SyncStatusIndicator(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await authViewModel.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}
