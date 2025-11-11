import 'dart:async'; // Timer Countdown
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Carousel Slider
import 'package:http/http.dart' as http; // ambil data API json
import 'dart:convert'; // Decode json
import 'package:geolocator/geolocator.dart'; // GPS
import 'package:geocoding/geocoding.dart'; // Konversi GPS
import 'package:intl/intl.dart'; // Formatter Number
import 'package:permission_handler/permission_handler.dart'; // Izin Handler
import 'package:shared_preferences/shared_preferences.dart'; // Cache Lokal
import 'package:string_similarity/string_similarity.dart'; // Fuzzy match Karanganyar = Karanganyar

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CarouselController _controller = CarouselController();
  int _currentIndex = 0;
  bool _isLoading = true;
  Duration? _timeRemaining;
  Timer? _countdownTimer;
  String _location = "Mengambil Lokasi....";
  String _prayTime = "Loading...";
  String _backgroundImage = 'assets/images/bg-morning.png';
  List<dynamic>? _jadwalSholat;

  //state untuk di jalankan diawal
  @override
  void initState() {
    super.initState();
  }

  final posterList = const <String>[
    'assets/images/ramadhan-karrem.png',
    'assets/images/idl-fitr.png',
    'assets/images/idl-adh.png',
  ];

  //fungsi teks remaining waktu sholat
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minute = d.inMinutes.remainder(60);
    return "$hours jam $minute menit lagi";
  }

  String _getBackgroundImage(DateTime now) async {
    if (now.hour < 12) {
      return 'assets/images/bg_morning.png';
    } else if (now.hour < 18){
      return 'assets/images/bg-afternoon.png';
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // ============================================
              // Menu waktu sholat by lokasi
              // ============================================
              _buildHeroSection(),
              SizedBox(height: 70,),
              // ============================================
              // Menu Section
              // ============================================
              _buildMenuGridSection(),
              // ============================================
              // Carousel Section
              // ============================================
              _buildCarouselSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // Menu hero widget
  // ============================================
  Widget _buildHeroSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 290,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFFB3E5FC),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
              ),
              image: DecorationImage(image: AssetImage('assets/images/bg-night.png'),
              fit: BoxFit.cover,
              ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Assalamu\'alaikum',
                  style: TextStyle(
                    fontFamily: 'Montserrat-Regular',
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Ngargoyoso',
                  style: TextStyle(fontFamily: 'Montserrat-Bold', fontSize: 22, color: Colors.white),
                ),
                Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: TextStyle(
                    fontFamily: 'Montserrat-Bold',
                    fontSize: 50,
                    height: 1.2,
                    color: Colors.white
                  ),
                ),
                
              ],
            ),
          ),
        ),

        // ========= WAKTU SHOLAT SELANJUTNYA ===========
        Positioned(
          bottom: -55,
          left: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  blurRadius: 2,
                  offset: Offset(0, 4),
                  color: Colors.black.withOpacity(0.4),
                )
              ]
            ),
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 14,
            ),
            child: Column(
              children: [
                Text(
                  'Waktu Sholat Berikutnya',
                  style: TextStyle(
                    fontFamily: 'Montserrat-Regular',
                    fontSize: 14,
                    color: Colors.black
                  ),
                ),
                Text(
                  'ASHAR',
                  style: TextStyle(
                    fontFamily: 'Montserrat-Bold',
                    fontSize: 20,
                    color: Colors.amber
                  ),
                ),
                Text(
                  '14:22',
                  style: TextStyle(
                    fontFamily: 'Montserrat-Bold',
                    fontSize: 28,
                    color: Colors.black26
                  ),
                ),
                Text(
                  '5 Jam 10 Menit',
                  style: TextStyle(
                    fontFamily: 'Montserrat-Regular',
                    fontSize: 13,
                    color: Colors.grey
                  ),
                )
              ],
            ),
          ),
        ),

      ],
    );
  }

  // =====================================================
  // MENU ITEM SECTION WIDGET
  // =====================================================
  Widget _buildMenuItem(String iconPath, String title, String routName) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, routName);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.amber.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              Image.asset(iconPath, width: 35),
              Text(title, style: TextStyle(fontFamily: 'Montserrat-Regular')),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // MENU GRID SECTION WIDGET
  // =====================================================
  Widget _buildMenuGridSection() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        physics: NeverScrollableScrollPhysics(),
        children: [
          _buildMenuItem('assets/images/ic_menu_doa.png', 'Doa', '/doa'),
          _buildMenuItem(
            'assets/images/ic_menu_jadwal_sholat.png',
            'Sholat',
            '/jadwal Sholat',
          ),
          _buildMenuItem(
            'assets/images/ic_menu_video_kajian.png',
            'Kajian',
            '/video Kajian',
          ),
          _buildMenuItem('assets/images/ic_menu_zakat.png', 'Zakat', '/zakat'),
          _buildMenuItem('assets/images/ic_menu_doa.png', 'Khutbah', '/doa'),
        ],
      ),
    );
  }

  // =====================================================
  // CAROUSEL SECTION WIDGET
  // =====================================================
  Widget _buildCarouselSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Carousel Card
        CarouselSlider.builder(
          itemCount: posterList.length,
          itemBuilder: (context, index, realIndex) {
            final poster = posterList[index];
            return Container(
              margin: EdgeInsets.all(15),
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(20),
                child: Image.asset(
                  poster,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
          options: CarouselOptions(
            autoPlay: true,
            height: 270,
            enlargeCenterPage: true,
            viewportFraction: 0.7,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
        ),
        // Dot Indikator Carousel
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: posterList.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _currentIndex.animateToPage(entry.key),
              child: Container(
                width: 10,
                height: 10,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == entry.key
                      ? Colors.amber
                      : Colors.grey[400],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

extension on int {
  void animateToPage(int key) {}
}
