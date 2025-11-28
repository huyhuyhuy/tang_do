import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tang_do.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT UNIQUE NOT NULL,
        nickname TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT,
        email TEXT,
        address TEXT,
        province TEXT,
        district TEXT,
        avatar TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        condition TEXT NOT NULL,
        address TEXT,
        province TEXT,
        district TEXT,
        ward TEXT,
        contact_phone TEXT,
        image1 TEXT,
        image2 TEXT,
        image3 TEXT,
        image4 TEXT,
        expiry_days INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Reviews table
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
        comment TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(product_id, user_id)
      )
    ''');

    // Follows table
    await db.execute('''
      CREATE TABLE follows (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        follower_id INTEGER NOT NULL,
        following_id INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (follower_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (following_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(follower_id, following_id)
      )
    ''');


    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT,
        related_id INTEGER,
        is_read INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for better performance
    await db.execute('CREATE INDEX idx_products_user_id ON products(user_id)');
    await db.execute('CREATE INDEX idx_products_category ON products(category)');
    await db.execute('CREATE INDEX idx_products_expires_at ON products(expires_at)');
    await db.execute('CREATE INDEX idx_reviews_product_id ON reviews(product_id)');
    await db.execute('CREATE INDEX idx_follows_follower ON follows(follower_id)');
    await db.execute('CREATE INDEX idx_follows_following ON follows(following_id)');
    await db.execute('CREATE INDEX idx_notifications_user_id ON notifications(user_id)');
    await db.execute('CREATE INDEX idx_notifications_is_read ON notifications(is_read)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add avatar column to users table
      await db.execute('ALTER TABLE users ADD COLUMN avatar TEXT');
    }
    if (oldVersion < 3) {
      // Add contact_phone to products table
      await db.execute('ALTER TABLE products ADD COLUMN contact_phone TEXT');
      
      // Drop goldchip_transactions table if exists
      try {
        await db.execute('DROP TABLE IF EXISTS goldchip_transactions');
      } catch (e) {
        // Ignore if table doesn't exist
      }
      
      // Drop referrals table if exists
      try {
        await db.execute('DROP TABLE IF EXISTS referrals');
      } catch (e) {
        // Ignore if table doesn't exist
      }
      
      // Remove gold_chip column from users table
      // SQLite doesn't support DROP COLUMN directly, so we need to recreate the table
      await db.execute('''
        CREATE TABLE users_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          phone TEXT UNIQUE NOT NULL,
          nickname TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          name TEXT,
          email TEXT,
          address TEXT,
          province TEXT,
          district TEXT,
          avatar TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      
      await db.execute('''
        INSERT INTO users_new (id, phone, nickname, password, name, email, address, province, district, avatar, created_at, updated_at)
        SELECT id, phone, nickname, password, name, email, address, province, district, avatar, created_at, updated_at
        FROM users
      ''');
      
      await db.execute('DROP TABLE users');
      await db.execute('ALTER TABLE users_new RENAME TO users');
    }
    if (oldVersion < 4) {
      // Add ward column to products table
      await db.execute('ALTER TABLE products ADD COLUMN ward TEXT');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

