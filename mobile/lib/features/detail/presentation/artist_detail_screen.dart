import 'package:flutter/material.dart';

class ArtistDetailScreen extends StatelessWidget {
  const ArtistDetailScreen({required this.mbid, super.key});

  final String mbid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail artiste')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Detail a implementer dans B2.\nMBID: $mbid',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
