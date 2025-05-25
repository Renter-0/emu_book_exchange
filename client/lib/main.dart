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
      textAlign: TextAlign.left,
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
      textAlign: TextAlign.left,
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

Future<Book> fetchBook() async {
  try {
    final response = await http
        .get(
          Uri.parse('$jsonServer/book/1'),
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

class Book {
  final int bookId;
  final int owner;
  final String title;
  final String author;
  final String category;
  final String condition;
  final String price;
  final String description;

  const Book({
    required this.bookId,
    required this.owner,
    required this.title,
    required this.category,
    required this.price,
    required this.author,
    required this.condition,
    required this.description,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    log('Received JSON: ${json.toString()}');
    return switch (json) {
      {
        'id': int id,
        'owner': int owner,
        'title': String title,
        'author': String author,
        'price': String price,
        'description': String description,
        'category': String category,
        'condition': String condition,
      } =>
        Book(
          owner: owner,
          title: title,
          bookId: id,
          price: price,
          author: author,
          description: description,
          category: category,
          condition: condition,
        ),
      _ =>
        throw const FormatException(
          'Incorrect data format while fetching book',
        ),
    };
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
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xF7F7F7F7),
      ),
      home: Scaffold(body: SafeArea(child: HomePage())),
    );
  }
}

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  late Future<Book> futureBook;

  @override
  void initState() {
    super.initState();
    futureBook = fetchBook();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Book>(
      future: futureBook,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            body: ListView(
              children: [
                Header(),
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
                                  image: NetworkImage('$server/1'),
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
                          Text('Description:\n${snapshot.data!.description}'),
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
        return const SizedBox(
          width: 89,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class MediumBookCard extends StatefulWidget {
  const MediumBookCard({super.key});

  @override
  State<MediumBookCard> createState() => _MediumBookCardState();
}

// Future<Book> delay() async {
//   await Future.delayed(const Duration(seconds: 2));
//   return Book.fromJson(testBook);
// }

class _MediumBookCardState extends State<MediumBookCard> {
  late Future<Book> futureBook;

  @override
  void initState() {
    super.initState();
    futureBook = fetchBook();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Book>(
      future: futureBook,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GestureDetector(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    BookCoverImage(
                      imageId: snapshot.data!.bookId,
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
                          RegularText(text: snapshot.data!.title, fontSize: 16),
                          Opacity(
                            opacity: 0.70,
                            child: RegularText(
                              text: snapshot.data!.author,
                              fontSize: 14,
                            ),
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
                          // TODO: Text should fill all the space it has. If text is bigger than container elipsis will be shown before the end
                          Opacity(
                            opacity: 0.70,
                            child: RegularText(
                              text: snapshot.data!.description,
                              fontSize: 14,
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
                MaterialPageRoute(builder: (context) => BookPage()),
              );
            },
          );
        } else if (snapshot.hasError) {
          return SnapshotErrorBox(error: snapshot.error!);
        }
        return const SizedBox(
          width: 89,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
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
  const CatalogPage({super.key});

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
              MediumBookCard(),
              MediumBookCard(),
              MediumBookCard(),
              MediumBookCard(),
              MediumBookCard(),
              MediumBookCard(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Footer(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const Header(),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SectionText(text: 'Recommendations'),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
          const LargeBookCard(),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.02),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(width: 16),
                SmallBookCard(),
                SizedBox(width: 16),
                SmallBookCard(),
                SizedBox(width: 16),
                SmallBookCard(),
                SizedBox(width: 16),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.02),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SectionText(text: 'Wishlist'),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(width: 16),
                SmallBookCard(),
                SizedBox(width: 16),
                SmallBookCard(),
                SizedBox(width: 16),
                SmallBookCard(),
                SizedBox(width: 16),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.02),
        ],
      ),
      bottomNavigationBar: Footer(),
    );
  }
}

class LargeBookCard extends StatelessWidget {
  const LargeBookCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.9;
    final height = MediaQuery.sizeOf(context).height * 0.3;

    return GestureDetector(
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Align(
            alignment: Alignment.center,
            child: BookCoverImage(heigth: height, width: width, imageId: 1),
          ),
          Padding(
            padding: EdgeInsets.only(left: width * 0.1),
            child: OnImageText(text: 'Book 1', fontSize: 16),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookPage()),
        );
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
                      MaterialPageRoute(builder: (context) => CatalogPage()),
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

class SmallBookCard extends StatefulWidget {
  const SmallBookCard({super.key});

  @override
  State<SmallBookCard> createState() => _SmallBookCardState();
}

class _SmallBookCardState extends State<SmallBookCard> {
  late Future<Book> futureBook;

  @override
  void initState() {
    super.initState();
    futureBook = fetchBook();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Book>(
      future: futureBook,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GestureDetector(
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BookCoverImage(
                    imageId: snapshot.data!.bookId,
                    width: 89,
                    heigth: 154,
                  ),
                  const SizedBox(height: 8),
                  RegularText(text: snapshot.data!.title, fontSize: 14),
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: 0.70,
                    child: RegularText(
                      text: snapshot.data!.author,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookPage()),
              );
            },
          );
        } else if (snapshot.hasError) {
          return SnapshotErrorBox(error: snapshot.error!);
        }
        return const SizedBox(
          width: 89,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
