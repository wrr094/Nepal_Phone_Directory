import 'package:flutter/material.dart';

import '../../features/contacts/domain/contact.dart';

IconData iconForCategory(String category) {
  final value = category.toLowerCase();
  if (value.contains('emergency')) return Icons.emergency_outlined;
  if (value.contains('police') || value.contains('security')) {
    return Icons.local_police_outlined;
  }
  if (value.contains('health') || value.contains('ambulance')) {
    return Icons.medical_services_outlined;
  }
  if (value.contains('hospital')) return Icons.local_hospital_outlined;
  if (value.contains('women') || value.contains('children')) {
    return Icons.family_restroom_outlined;
  }
  if (value.contains('government complaints')) return Icons.campaign_outlined;
  if (value.contains('government')) return Icons.account_balance_outlined;
  if (value.contains('electricity') || value.contains('utilities')) {
    return Icons.electrical_services_outlined;
  }
  if (value.contains('disaster') || value.contains('rescue')) {
    return Icons.crisis_alert_outlined;
  }
  if (value.contains('travel') || value.contains('tourism')) {
    return Icons.travel_explore_outlined;
  }
  if (value.contains('information') || value.contains('inquiry')) {
    return Icons.info_outline;
  }
  if (value.contains('ward')) return Icons.location_city_outlined;
  return Icons.folder_outlined;
}

IconData iconForEmergencyContact(Contact contact) {
  final label =
      '${contact.organisationName} ${contact.subcategory}'.toLowerCase();
  final number = contact.hotlineCode;
  if (label.contains('police') && label.contains('traffic')) {
    return Icons.traffic_outlined;
  }
  if (label.contains('police')) return Icons.local_police_outlined;
  if (label.contains('fire') || number.contains('101')) {
    return Icons.local_fire_department_outlined;
  }
  if (label.contains('ambulance') || number.contains('102')) {
    return Icons.emergency_share_outlined;
  }
  if (label.contains('child')) return Icons.child_care_outlined;
  if (label.contains('women')) return Icons.family_restroom_outlined;
  if (label.contains('tourist')) return Icons.travel_explore_outlined;
  if (label.contains('disaster') || label.contains('neoc')) {
    return Icons.crisis_alert_outlined;
  }
  if (label.contains('electricity') || label.contains('nea')) {
    return Icons.electrical_services_outlined;
  }
  if (label.contains('sarkar')) return Icons.campaign_outlined;
  if (label.contains('ministry')) return Icons.account_balance_outlined;
  return Icons.phone_in_talk_outlined;
}
