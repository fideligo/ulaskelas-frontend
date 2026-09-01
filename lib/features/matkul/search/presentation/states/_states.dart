// Created by Muhamad Fauzi Ridwan on 07/11/21.

import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ristek_material_component/ristek_material_component.dart';
import 'package:ulaskelas/core/_core.dart';
import 'package:ulaskelas/core/client/_client.dart';
import 'package:ulaskelas/core/environment/_environment.dart';
import 'package:ulaskelas/core/error/_error.dart';
import 'package:ulaskelas/features/matkul/main/data/datasources/_datasources.dart';
import 'package:ulaskelas/features/matkul/main/data/repositories/_repositories.dart';
import 'package:ulaskelas/features/matkul/main/domain/entities/query_search_course.dart';
import 'package:ulaskelas/features/matkul/main/domain/repositories/_repositories.dart';
import 'package:ulaskelas/features/matkul/search/data/models/_models.dart';
import 'package:ulaskelas/features/matkul/search/domain/entities/_entities.dart';

import '../../../../../services/_services.dart';

part 'filter_state.dart';
part 'search_course_state.dart';
