//------------------------------------------  Database
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

const String databaseName = "pa_systems_stages.db";

//------------------------------------------  Padding
final EdgeInsets hPadding = const EdgeInsets.symmetric(horizontal: 16);

//------------------------------------------  Date Format
final kTimeFormate = intl.DateFormat.jm();
final intl.DateFormat kSlashDateFormat = intl.DateFormat('dd/MM/yyyy');
final intl.DateFormat kDateFormat = intl.DateFormat('dd MMM, yyyy');
