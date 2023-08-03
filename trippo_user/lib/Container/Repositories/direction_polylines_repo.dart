import 'package:dio/dio.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trippo_user/Container/utils/keys.dart';
import 'package:trippo_user/Model/direction_polyline_details_model.dart';
import 'package:trippo_user/View/Screens/Main_Screens/home_screen.dart';

final directionPolylinesRepoProvider = Provider<DirectionPolylines>((ref) {
  return DirectionPolylines();
});

class DirectionPolylines {
  Future<dynamic> getDirectionsPolylines(
      context, WidgetRef ref, controller) async {
    try {
      LatLng pickUpDestination = LatLng(
          ref.read(pickUpLocationProvider)!.locationLatitude!,
          ref.read(pickUpLocationProvider)!.locationLongitude!);
      LatLng dropOffDestination = LatLng(
          ref.read(dropOffLocationProvider)!.locationLatitude!,
          ref.read(dropOffLocationProvider)!.locationLongitude!);

      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${pickUpDestination.latitude},${pickUpDestination.longitude}&destination=${dropOffDestination.latitude},${dropOffDestination.longitude}&key=$mapKey";

      Response res = await Dio().get(url);

      if (res.statusCode == 200) {
        DirectionPolylineDetails model = DirectionPolylineDetails(
          epoints: res.data["routes"][0]["overview_polyline"]["points"],
          distanceText: res.data["routes"][0]["legs"][0]["distance"]["text"],
          distanceValue: res.data["routes"][0]["legs"][0]["distance"]["value"],
          durationText: res.data["routes"][0]["legs"][0]["duration"]["text"],
          durationValue: res.data["routes"][0]["legs"][0]["duration"]["value"],
        );

        ref.read(directionPolylinesProvider.notifier).update((state) => model);
        return model;
      } else {
        ElegantNotification.error(description: const Text("Failed to get data"))
            .show(context);
      }
    } catch (e) {
      print("error data is $e");
      ElegantNotification.error(description: Text("An Error Occurred $e"))
          .show(context);
    }
  }

  List<LatLng> pLinesCoordinatedList = [];

  void setNewDirectionPolylines(ref, context, controller) async {
    try {
      DirectionPolylineDetails model =
          await getDirectionsPolylines(context, ref, controller);

      PolylinePoints points = PolylinePoints();
      List<PointLatLng> decodedPolylines =
          points.decodePolyline(model.epoints!);

      pLinesCoordinatedList.clear();

      if (decodedPolylines.isNotEmpty) {
        for (PointLatLng polyline in decodedPolylines) {
          pLinesCoordinatedList
              .add(LatLng(polyline.latitude, polyline.longitude));
        }
      }

      ref.read(mainPolylinesProvider).clear();

      Polyline newPolyline = Polyline(
          color: Colors.blue,
          polylineId: const PolylineId("polylineId"),
          jointType: JointType.round,
          points: pLinesCoordinatedList,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
          width: 5);

      ref
          .read(mainPolylinesProvider.notifier)
          .update((Set<Polyline> state) => {...state, newPolyline});

      print("new plist is $pLinesCoordinatedList");

      LatLngBounds bounds;

      if (ref.read(pickUpLocationProvider)!.locationLatitude! >
              ref.read(dropOffLocationProvider)!.locationLatitude! &&
          ref.read(pickUpLocationProvider)!.locationLongitude! >
              ref.read(dropOffLocationProvider)!.locationLongitude!) {
        bounds = LatLngBounds(
            southwest: LatLng(
                ref.read(pickUpLocationProvider)!.locationLatitude!,
                ref.read(dropOffLocationProvider)!.locationLongitude!),
            northeast: LatLng(
                ref.read(dropOffLocationProvider)!.locationLatitude!,
                ref.read(pickUpLocationProvider)!.locationLongitude!));
      } else if (ref.read(pickUpLocationProvider)!.locationLatitude! >
          ref.read(dropOffLocationProvider)!.locationLatitude!) {
        bounds = LatLngBounds(
            southwest: LatLng(
                ref.read(dropOffLocationProvider)!.locationLatitude!,
                ref.read(pickUpLocationProvider)!.locationLongitude!),
            northeast: LatLng(
                ref.read(pickUpLocationProvider)!.locationLatitude!,
                ref.read(dropOffLocationProvider)!.locationLongitude!));
      } else {
        bounds = LatLngBounds(
            southwest: LatLng(
                ref.read(pickUpLocationProvider)!.locationLatitude!,
                ref.read(pickUpLocationProvider)!.locationLongitude!),
            northeast: LatLng(
                ref.read(dropOffLocationProvider)!.locationLatitude!,
                ref.read(dropOffLocationProvider)!.locationLongitude!));

        controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 65));
      }
    } catch (e) {
      ElegantNotification.error(
          description: Text(
        "An Error Occurred $e",
        style: const TextStyle(color: Colors.black),
      )).show(context);

      print("the error is $e");
    }
  }
}
