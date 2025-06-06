import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const accentColor = Color(0xFFCCE5E3);

const jsonServer =
    '${String.fromEnvironment('SERVER', defaultValue: 'localhost')}/api';
const server = "$jsonServer/image";

/// Custom Text Widgets

/// Styled to be visible on different backgrounds
class OnImageText extends StatelessWidget {
  final String text;
  final double? fontSize;
  const OnImageText({super.key, required this.text, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        color: Colors.white,
        shadows: [
          Shadow(blurRadius: 5, color: Colors.black, offset: Offset(1, 1)),
        ],
      ),
    );
  }
}

/// Text that is used to mark important/big sections
class SectionText extends StatelessWidget {
  final String text;
  const SectionText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.black,
        fontSize: MediaQuery.sizeOf(context).width * 0.05,
        fontFamily: 'Instrument Sans',
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Text configured to be used in other parts of the app
class RegularText extends StatelessWidget {
  final String text;
  final double? fontSize;
  const RegularText({super.key, required this.text, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class SnapshotErrorBox extends StatelessWidget {
  final Object error;
  const SnapshotErrorBox({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 89,
      height: 200,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            'Error loading book',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[700], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

Future<Book> fetchBook(int bookId) async {
  try {
    final response = await http
        .get(
          Uri.parse('$jsonServer/book/$bookId'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return Book.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception(
        'Failed to load book. Status code: ${response.statusCode}',
      );
    }
  } catch (e) {
    log('Error fetching book: $e');
    throw Exception('Network error: $e');
  }
}

Future<List<Book>> fetchBooks(String endpoint, String? search) async {
  final end = switch (endpoint) {
    'catalog' => search != null ? 'catalog/$search' : 'catalog',
    _ => '',
  };
  try {
    final response = await http
        .get(
          Uri.parse('$jsonServer/$end'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load books. Status code: ${response.statusCode}',
      );
    }
    log(response.body);
    final payload = List.from((jsonDecode(response.body)).values);
    log(payload.toString());
    return payload.map((elem) => Book.fromJson(elem)).toList();
  } catch (e) {
    log('Error fetching book: $e');
    throw Exception('Network error: $e');
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email validation function
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation function
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  // Login function
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$jsonServer/log_in/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // TODO: Store and utilize token returned by API

        // Navigate to home page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              errorData['error'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check your connection.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Sign in to your account',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: accentColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () {
                            // TODO: Create SingUpPage
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Book {
  final int bookId;
  final int? owner;
  final String title;
  final String author;
  final String? category;
  final String? condition;
  final String? price;
  final String? description;

  const Book({
    required this.author,
    required this.bookId,
    required this.title,
    this.category,
    this.condition,
    this.description,
    this.owner,
    this.price,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    log('Received JSON: ${json.toString()}');
    return Book(
      owner: json['owner'],
      title: json['title']!,
      bookId: json['id']!,
      price: json['price'],
      author: json['author']!,
      description: json['description'] ?? '',
      category: json['category'],
      condition: json['condition'] ?? 'UD',
    );
  }
}

void main() {
  runApp(const BookExchangeApp());
}

class BookExchangeApp extends StatelessWidget {
  const BookExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Exchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xF7F7F7F7),
      ),
      home: Scaffold(body: SafeArea(child: LoginPage())),
    );
  }
}

class BookPage extends StatefulWidget {
  const BookPage({super.key, required this.bookId});
  final int bookId;

  @override
  State<BookPage> createState() => _BookPageState(bookId);
}

class _BookPageState extends State<BookPage> {
  _BookPageState(this.bookId);
  late Future<Book> futureBook;
  final int bookId;

  @override
  void initState() {
    super.initState();
    futureBook = fetchBook(bookId);
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.sizeOf(context).height * 0.12;
    final headerWidth = MediaQuery.sizeOf(context).width;
    return FutureBuilder<Book>(
      future: futureBook,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            body: ListView(
              children: [
                Container(
                  height: headerHeight,
                  color: accentColor,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      headerWidth * 0.05,
                      headerHeight * 0.3,
                      headerWidth * 0.05,
                      headerHeight * 0.1,
                    ),
                    child: Row(
                      children: [
                        BackButton(),
                        Container(
                          width: 257,
                          height: 40,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            shadows: [
                              BoxShadow(
                                color: Color(0x3F000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Container(
                                  width: 257,
                                  height: 40,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFF7F7F7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Positioned(
                                  left: 13,
                                  top: 3,
                                  child: Text(
                                    snapshot.data!.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontFamily: 'Inknut Antiqua',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        ProfileButton(),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.maxFinite,
                      height: MediaQuery.sizeOf(context).height * 0.6,
                      child: Stack(
                        children: [
                          // Blurred background
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    '$server/${snapshot.data!.bookId}',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: ClipRRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaY: 10,
                                    sigmaX: 10,
                                  ),
                                  child: Container(
                                    color: Colors.black.withOpacity(
                                      0.1,
                                    ), // Optional overlay
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Clear centered image
                          Center(
                            child: BookCoverImage(
                              imageId: snapshot.data!.bookId,
                              width: 167,
                              heigth: 281,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: OnImageText(
                                text: snapshot.data!.author,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 25.0),
                          child: Container(
                            width: 179,
                            height: 55,
                            decoration: ShapeDecoration(
                              color: accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RegularText(
                                    text:
                                        'Send exchange request to ${snapshot.data!.owner}',
                                    fontSize: 12,
                                  ),
                                ),
                                Container(
                                  height: 55,
                                  decoration: ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        width: 1,
                                        strokeAlign:
                                            BorderSide.strokeAlignCenter,
                                      ),
                                    ),
                                  ),
                                ),
                                Icon(Icons.share),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 179,
                          height: 55,
                          decoration: ShapeDecoration(
                            color: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: RegularText(
                                  text: "Add to Wishlist",
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                height: 55,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      strokeAlign: BorderSide.strokeAlignCenter,
                                    ),
                                  ),
                                ),
                              ),
                              Icon(Icons.star),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 369,
                      height: 334,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(29),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Condition: ${switch (snapshot.data!.condition) {
                              'NW' => 'New',
                              'UD' => 'Used',
                              'OD' => 'Old',
                              _ => '',
                            }}',
                          ),
                          Text('Price: ${snapshot.data!.price}'),
                          Text(
                            'Description:\n${snapshot.data!.description}',
                            maxLines: 13,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return SnapshotErrorBox(error: snapshot.error!);
        }
        return LoadingBox();
      },
    );
  }
}

class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 89,
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class MediumBookCard extends StatelessWidget {
  const MediumBookCard({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              BookCoverImage(
                imageId: book.bookId,
                width: 141,
                heigth: 177,
                withWishlist: true,
              ),
              // Book details' Box
              Container(
                width: 257,
                height: 127,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1.5,
                  children: [
                    RegularText(text: book.title, fontSize: 16),
                    Opacity(
                      opacity: 0.70,
                      child: RegularText(text: book.author, fontSize: 14),
                    ),
                    Opacity(
                      opacity: 0.50,
                      child: Container(
                        width: 257,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              strokeAlign: BorderSide.strokeAlignCenter,
                            ),
                          ),
                          shadows: [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0.70,
                      child: Text(
                        book.description ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookPage(bookId: book.bookId),
          ),
        );
      },
    );
  }
}

class BookCoverImage extends StatelessWidget {
  final int imageId;
  final double width;
  final double heigth;
  final bool withWishlist;
  const BookCoverImage({
    super.key,
    required this.imageId,
    required this.width,
    required this.heigth,
    this.withWishlist = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: heigth,
      decoration: ShapeDecoration(
        image: DecorationImage(
          image: NetworkImage('$server/$imageId'),
          fit: BoxFit.cover,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(width: 1),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child:
          withWishlist
              ? Align(
                alignment: Alignment(0.9, -0.8),
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: CircleBorder(),
                  ),
                  child: Icon(Icons.star, color: Colors.yellow, size: 15),
                ),
              )
              : null,
    );
  }
}

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key, this.search});

  final String? search;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(),
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
            ],
          ),
          MediumBookCardScroller(search: search),
        ],
      ),
      bottomNavigationBar: Footer(),
    );
  }
}

class MediumBookCardScroller extends StatefulWidget {
  const MediumBookCardScroller({super.key, this.search});

  final String? search;

  @override
  State<MediumBookCardScroller> createState() =>
      _MediumBookCardScroller(search);
}

class _MediumBookCardScroller extends State<MediumBookCardScroller> {
  _MediumBookCardScroller(this.search);
  late Future<List<Book>> books;
  final String? search;

  @override
  void initState() {
    super.initState();
    books = fetchBooks('catalog', search);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: books,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children:
                snapshot.data!
                    .map((book) => MediumBookCard(book: book))
                    .toList(),
          );
        } else if (snapshot.hasError) {
          return SnapshotErrorBox(error: snapshot.error!);
        } else {
          return LoadingBox();
        }
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.sizeOf(context).height * 0.12;
    final headerWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: ListView(
        children: [
          Container(
            height: headerHeight,
            color: accentColor,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                headerWidth * 0.05,
                headerHeight * 0.3,
                headerWidth * 0.05,
                headerHeight * 0.1,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    child: Icon(Icons.shopping_cart, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CatalogPage()),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onSubmitted: (String value) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CatalogPage(search: value),
                            ),
                          );
                        },
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          hintText: 'Search books...',
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  ProfileButton(),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SectionText(text: 'Recommendations'),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
          const LargeBookCard(bookId: 2),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.02),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SmallBookCardScroller(),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.02),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SectionText(text: 'Wishlist'),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SmallBookCardScroller(),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.02),
        ],
      ),
      bottomNavigationBar: Footer(),
    );
  }
}

class LargeBookCard extends StatefulWidget {
  const LargeBookCard({super.key, required this.bookId});

  final int bookId;

  @override
  State<LargeBookCard> createState() => _LargeBookCardState(bookId);
}

class _LargeBookCardState extends State<LargeBookCard> {
  _LargeBookCardState(this.bookId);
  late Future<Book> book;
  final int bookId;

  @override
  void initState() {
    super.initState();
    book = fetchBook(bookId);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.9;
    final height = MediaQuery.sizeOf(context).height * 0.3;

    return FutureBuilder(
      future: book,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GestureDetector(
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: BookCoverImage(
                    heigth: height,
                    width: width,
                    imageId: snapshot.data!.bookId,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: width * 0.1),
                  child: OnImageText(text: snapshot.data!.title, fontSize: 16),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookPage(bookId: snapshot.data!.bookId),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return SnapshotErrorBox(error: snapshot.error!);
        } else {
          return LoadingBox();
        }
      },
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.04;
    return Container(height: height, color: accentColor);
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.sizeOf(context).height * 0.12;
    final headerWidth = MediaQuery.sizeOf(context).width;

    return Container(
      height: headerHeight,
      color: accentColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          headerWidth * 0.05,
          headerHeight * 0.3,
          headerWidth * 0.05,
          headerHeight * 0.1,
        ),
        child: Row(
          children: [
            BackButton(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onSubmitted: (String value) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CatalogPage(search: value),
                      ),
                    );
                  },
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    hintText: 'Search books...',
                    hintStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            ProfileButton(),
          ],
        ),
      ),
    );
  }
}

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.person, color: Colors.grey, size: 24),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      },
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: Center(
        child: Column(
          spacing: screenHeight * 0.03,
          children: [
            Container(
              height: screenHeight * 0.05,
              color: accentColor,
              alignment: Alignment.topLeft,
              child: BackButton(),
            ),
            Icon(Icons.person, color: Colors.grey, size: screenHeight * 0.1),
            // TODO: Implement profile, password and name editing
            Button(text: 'Edit Profile Picture'),
            Button(text: 'Change Password'),
            Button(text: 'Change Name'),
            Button(
              text: 'Exit App',
              onTap: () {
                SystemNavigator.pop();
              },
            ),
            Button(color: const Color(0xFFE43535), text: 'Delete Account'),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: accentColor,
        height: MediaQuery.sizeOf(context).height * 0.04,
      ),
    );
  }
}

class Button extends StatelessWidget {
  const Button({
    super.key,
    this.screenHeight,
    this.screenWidth,
    required this.text,
    this.onTap,
    this.color = accentColor,
  });

  final double? screenHeight;
  final double? screenWidth;
  final Color color;
  final String text;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: screenHeight ?? MediaQuery.sizeOf(context).height * 0.1,
        width: screenWidth ?? MediaQuery.sizeOf(context).width * 0.5,
        decoration: ShapeDecoration(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class SmallBookCardScroller extends StatefulWidget {
  const SmallBookCardScroller({super.key});

  @override
  State<SmallBookCardScroller> createState() => _SmallBookCardScroller();
}

class _SmallBookCardScroller extends State<SmallBookCardScroller> {
  late Future<List<Book>> books;
  @override
  void initState() {
    super.initState();
    books = fetchBooks('home', null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: books,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Row(
            spacing: 16,
            children:
                snapshot.data!
                    .map(
                      (book) => SmallBookCard(
                        bookId: book.bookId,
                        title: book.title,
                        author: book.author,
                      ),
                    )
                    .toList(),
          );
        } else if (snapshot.hasError) {
          return SnapshotErrorBox(error: snapshot.error!);
        }
        return LoadingBox();
      },
    );
  }
}

class SmallBookCard extends StatelessWidget {
  const SmallBookCard({
    super.key,
    required this.bookId,
    required this.title,
    required this.author,
  });

  final int bookId;
  final String title;
  final String author;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BookCoverImage(imageId: bookId, width: 89, heigth: 154),
            const SizedBox(height: 8),
            Center(child: RegularText(text: title, fontSize: 14)),
            const SizedBox(height: 4),
            Center(
              child: Opacity(
                opacity: 0.70,
                child: RegularText(text: author, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookPage(bookId: bookId)),
        );
      },
    );
  }
}
