import 'package:flutter_test/flutter_test.dart';
import 'package:traveler_app/widgets/ai_itinerary_prompt_bar.dart';

void main() {
  group('AiPromptParser Tests', () {
    test('Parses user prompt with time, family, budget and street food', () {
      const prompt = 'I have 2 hr with family my budget is 1500 and want street food';
      final result = AiPromptParser.parse(prompt);

      expect(result.time, '2');
      expect(result.timeUnit, 'Hours');
      expect(result.groupType, 'Family');
      expect(result.travelerCount, 4);
      expect(result.budget, 1500.0);
      expect(result.interests, contains('Food'));
    });

    test('Parses solo food and heritage in Panvel', () {
      const prompt = 'Solo 3 hrs food and heritage tour in Panvel under ₹800';
      final result = AiPromptParser.parse(prompt);

      expect(result.destination, 'Panvel');
      expect(result.time, '3');
      expect(result.groupType, 'Solo');
      expect(result.travelerCount, 1);
      expect(result.budget, 800.0);
      expect(result.interests, contains('Food'));
      expect(result.interests, contains('Heritage'));
    });

    test('Parses couple half day nature and adventure with 2.5k budget', () {
      const prompt = 'Half day couple nature & adventure trail budget 2.5k in Lonavala';
      final result = AiPromptParser.parse(prompt);

      expect(result.destination, 'Lonavala');
      expect(result.time, '4');
      expect(result.timeUnit, 'Hours');
      expect(result.groupType, 'Couple');
      expect(result.travelerCount, 2);
      expect(result.budget, 2500.0);
      expect(result.interests, contains('Nature'));
      expect(result.interests, contains('Adventure'));
    });

    test('Parses 4 friends full day trip with budget ₹5,000 in Mumbai', () {
      const prompt = 'Full day trip in Mumbai with 4 friends budget is ₹5,000';
      final result = AiPromptParser.parse(prompt);

      expect(result.destination, 'Mumbai');
      expect(result.time, '8');
      expect(result.groupType, 'Friends');
      expect(result.travelerCount, 4);
      expect(result.budget, 5000.0);
    });
  });
}
