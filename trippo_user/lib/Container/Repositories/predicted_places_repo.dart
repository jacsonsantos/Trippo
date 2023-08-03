import 'package:dio/dio.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trippo_user/Container/utils/keys.dart';
import 'package:trippo_user/Model/predicted_places.dart';

import '../../View/Screens/Main_Screens/Sub_Screens/where_to_screen.dart';

final predictedPlacesRepoProvider = Provider<PredictedPlacesRepo>((ref) {
  return PredictedPlacesRepo();
});

class PredictedPlacesRepo {
  void getAllPredictedPlaces(
      String text, BuildContext context, WidgetRef ref) async {
    try {
      if (text.length < 2) {
        return;
      }
      String url =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$text&key=$mapKey&components=country:pk";

      Response res = await Dio().get(url);

      if (res.statusCode == 200) {
        var placePrediction = res.data["predictions"];

        var predictedPlacesList = (placePrediction as List)
            .map((e) => PredictedPlaces.fromJson(e))
            .toList();

        ref
            .read(predictedPlacesProvider.notifier)
            .update((state) => predictedPlacesList);
      } else {
        if (context.mounted) {
          ElegantNotification.error(
                  description: const Text("Failed to get data"))
              .show(context);
        }
      }
    } catch (e) {
      print("error data is $e");
      ElegantNotification.error(description: Text("An Error Occurred $e"))
          .show(context);
    }
  }
}