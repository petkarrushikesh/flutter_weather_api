import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_weather_api/api.dart';
import 'package:flutter_weather_api/weathermodel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ApiResponse? response;
  bool inProgress = false;
  String message = "Search for the location to get weather data";
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLastSearchedCity();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://th.bing.com/th/id/OIP.H-dSQPes3S8JE2F_ko58qwHaOz?w=115&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7"),
                fit: BoxFit.cover,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSearchWidget(),
                const SizedBox(height: 20),
                if (inProgress)
                  CircularProgressIndicator()
                else
                  Expanded(
                      child: SingleChildScrollView(child: _buildWeatherWidget())),
              ],
            ),
          ),
        )
    );
  }

  Widget _buildSearchWidget() {
    return SearchBar(
      hintText: "Search any location",
      hintStyle:  MaterialStateProperty.all(TextStyle(color: Colors.red)),
      controller: _searchController,
      onSubmitted: (value) {
        _getWeatherData(value);
      },
    );
  }

  Widget _buildWeatherWidget() {
    if (response == null) {
      return Text(message);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.location_on, color: Colors.white,
                size: 50,
              ),
              Text(
                response?.location?.name ?? "",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
              Text(
                response?.location?.country ?? "",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  (response?.current?.tempC.toString() ?? "") + " °c",
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                (response?.current?.condition?.text.toString() ?? ""),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Center(
            child: SizedBox(
              height: 200,
              child: Image.network(
                "https:${response?.current?.condition?.icon}".replaceAll("64x64", "128x128"),
                scale: 0.7,
              ),
            ),
          ),
          Card(
            elevation: 4,
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _dataAndTitleWidget("Humidity", response?.current?.humidity?.toString() ?? ""),
                    _dataAndTitleWidget("Wind Speed", "${response?.current?.windKph?.toString() ?? ""} km/h"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _dataAndTitleWidget("UV", response?.current?.uv?.toString() ?? ""),
                    _dataAndTitleWidget("Precipitation", "${response?.current?.precipMm?.toString() ?? ""} mm"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _dataAndTitleWidget("Local Time", response?.location?.localtime?.split(" ").last ?? ""),
                    _dataAndTitleWidget("Local Date", response?.location?.localtime?.split(" ").first ?? ""),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _dataAndTitleWidget(String title, String data) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Text(
            data,
            style: const TextStyle(
              fontSize: 27,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadLastSearchedCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastSearchedCity = prefs.getString('lastSearchedCity');
    if (lastSearchedCity != null) {
      _searchController.text = lastSearchedCity;
      _getWeatherData(lastSearchedCity);
    }
  }

  Future<void> _saveLastSearchedCity(String city) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSearchedCity', city);
  }

  Future<void> _getWeatherData(String location) async {
    setState(() {
      inProgress = true;
    });

    try {
      response = await WeatherApi().getCurrentWeather(location);
      await _saveLastSearchedCity(location);
    } catch (e) {
      setState(() {
        message = "Failed to get weather data";
        response = null;
      });
    } finally {
      setState(() {
        inProgress = false;
      });
    }
  }
}
