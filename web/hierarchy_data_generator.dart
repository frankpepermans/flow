library flow.hierarchy_data_generator;

import 'dart:math';

import 'package:faker/faker.dart';

class HierarchyDataGenerator {

  HierarchyDataGenerator();

  void generate(int count) {
    final Random random = new Random();
    final Iterable<Person> people = getPeople(count);


  }

  Iterable<Person> getPeople(int count) sync* {
    final Random random = new Random();
    final Faker faker = new Faker();
    int i = 0;

    while (i++ < count) yield new Person(
      faker.person.firstName(),
      faker.person.lastName(),
      faker.company.position(),
      faker.job.title(),
      faker.address.city(),
      'images/bigshot${new String.fromCharCode(65 + random.nextInt(10))}'
    );
  }

}

class Person {

  final String firstName, lastName, jobMain, jobTitle, city, image;

  Person(this.firstName, this.lastName, this.jobMain, this.jobTitle, this.city, this.image);

  String toString() => <String, dynamic>{
    'firstName': firstName,
    'lastName': lastName,
    'jobMain': jobMain,
    'jobTitle': jobTitle,
    'city': city,
    'image': image
  }.toString();

}