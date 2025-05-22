import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const jsonServer =
    "https://sunglasses-exotic-begun-assignments.trycloudflare.com/api";
const server = "$jsonServer/image";

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
  final String title;
  final String author;
  final String category;
  final String condition;
  final String price;
  final String description;

  const Book({
    required this.bookId,
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
        'owner': int _,
        'title': String title,
        'author': String author,
        'price': String price,
        'description': String description,
        'category': String category,
        'condition': String condition,
      } =>
        Book(
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
      home: Scaffold(
        body: SafeArea(child: ListView(children: [CatalogPage()])),
      ),
    );
  }
}

class MediumBookCard extends StatefulWidget {
  const MediumBookCard({super.key});

  @override
  State<MediumBookCard> createState() => _MediumBookCardState();
}

Future<Book> delay() async {
  await Future.delayed(const Duration(seconds: 2));
  return Book.fromJson(testBook);
}

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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Image Box
                  Container(
                    width: 141,
                    height: 177,
                    decoration: ShapeDecoration(
                      image: DecorationImage(
                        image: NetworkImage('$server/${snapshot.data!.bookId}'),
                        fit: BoxFit.cover,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                    child: Align(
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
                    ),
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
                        Text(
                          snapshot.data!.title,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Opacity(
                          opacity: 0.70,
                          child: Text(
                            'By ${snapshot.data!.author}',
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
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
                          child: Text(
                            snapshot.data!.description,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
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
          );
        } else if (snapshot.hasError) {
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
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          );
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

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const Footer(),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Header(),
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Recommendations',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.black,
              fontSize: MediaQuery.sizeOf(context).width * 0.05,
              fontFamily: 'Instrument Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
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
          child: Text(
            'Wishlist',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.black,
              fontSize: MediaQuery.sizeOf(context).width * 0.05,
              fontFamily: 'Instrument Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
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
        const Footer(),
      ],
    );
  }
}

class LargeBookCard extends StatelessWidget {
  const LargeBookCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.9;
    final height = MediaQuery.sizeOf(context).height * 0.3;

    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          image: const DecorationImage(
            image: NetworkImage('$server/1'),
            fit: BoxFit.cover,
          ),
          color: const Color(0xFFD9D9D9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: height * 0.75,
              left: width * 0.05,
              right: width * 0.05,
            ),
            child: const Text(
              'Book Name - Owner',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.08;
    return Container(
      height: height,
      color: const Color(0xFFCCE5E3),
      child: const Center(
        child: Text(
          'Book Exchange App',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
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
      color: const Color(0xFFCCE5E3),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          headerWidth * 0.05,
          headerHeight * 0.3,
          headerWidth * 0.05,
          headerHeight * 0.1,
        ),
        child: Row(
          children: [
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
                child: const TextField(
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
            Container(
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
          ],
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
          return SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 89,
                  height: 154,
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                      image: NetworkImage('$server/${snapshot.data!.bookId}'),
                      fit: BoxFit.cover,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.data!.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Opacity(
                  opacity: 0.70,
                  child: Text(
                    snapshot.data!.author,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
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
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          );
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
