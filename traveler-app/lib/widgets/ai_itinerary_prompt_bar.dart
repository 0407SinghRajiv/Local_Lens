import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/locallens_design_system.dart';

/// Parsed result model from natural language AI prompt
class AiPromptParsedResult {
  final String? destination;
  final String? time;
  final String? timeUnit;
  final double? budget;
  final String? groupType;
  final int? travelerCount;
  final List<String> interests;
  final String rawPrompt;

  const AiPromptParsedResult({
    this.destination,
    this.time,
    this.timeUnit = 'Hours',
    this.budget,
    this.groupType,
    this.travelerCount,
    this.interests = const [],
    required this.rawPrompt,
  });

  bool get hasAnyExtraction =>
      destination != null ||
      time != null ||
      budget != null ||
      groupType != null ||
      interests.isNotEmpty;
}

/// Natural Language AI Parser for trip prompts
class AiPromptParser {
  AiPromptParser._();

  static const List<String> knownCities = [
    'Panvel',
    'Mumbai',
    'Kharghar',
    'Navi Mumbai',
    'Pune',
    'Lonavala',
    'Alibaug',
    'Matheran',
    'Thane',
    'Nashik',
    'Ratnagiri',
    'South Mumbai',
    'Bandra',
    'Colaba',
    'Juhu',
    'Khandala',
    'Mahabaleshwar',
  ];

  static const Map<String, List<String>> interestKeywords = {
    'Food': ['food', 'street food', 'misal', 'seafood', 'eat', 'dining', 'snack', 'cafe', 'restaurant', 'pav', 'dish'],
    'Culture': ['culture', 'temple', 'art', 'museum', 'tradition', 'spiritual', 'monastery'],
    'Adventure': ['adventure', 'trek', 'hiking', 'climb', 'thrill', 'sports', 'kayak'],
    'Nature': ['nature', 'park', 'garden', 'hills', 'waterfall', 'lake', 'green', 'viewpoint', 'forest'],
    'Heritage': ['heritage', 'fort', 'monument', 'historic', 'history', 'caves', 'palace'],
    'Beach': ['beach', 'sea', 'coastal', 'ocean', 'sand', 'shore'],
    'Shopping': ['shopping', 'market', 'bazaar', 'crafts', 'souvenir', 'mall', 'buy'],
    'Nightlife': ['nightlife', 'club', 'lounge', 'bar', 'evening', 'party'],
    'Photography': ['photography', 'photos', 'photo', 'scenic', 'instagram', 'view'],
    'Wellness': ['wellness', 'spa', 'yoga', 'relax', 'peace', 'meditation'],
    'Hidden Gems': ['hidden gem', 'hidden gems', 'secret', 'offbeat', 'unexplored'],
    'Local Experiences': ['local', 'authentic', 'village', 'workshop', 'walk', 'experience'],
  };

  static AiPromptParsedResult parse(String prompt) {
    if (prompt.trim().isEmpty) {
      return AiPromptParsedResult(rawPrompt: prompt);
    }

    final lower = prompt.toLowerCase();

    // 1. Extract Time / Duration
    String? extractedTime;
    String extractedUnit = 'Hours';

    if (lower.contains('half day') || lower.contains('half-day')) {
      extractedTime = '4';
      extractedUnit = 'Hours';
    } else if (lower.contains('full day') || lower.contains('full-day') || lower.contains('whole day')) {
      extractedTime = '8';
      extractedUnit = 'Hours';
    } else {
      // Regex for e.g. "2 hr", "2 hours", "2.5 hrs", "3hrs", "4 h"
      final hoursMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:hours?|hrs?|hr|h\b)', caseSensitive: false).firstMatch(lower);
      if (hoursMatch != null) {
        extractedTime = hoursMatch.group(1);
        extractedUnit = 'Hours';
      } else {
        final daysMatch = RegExp(r'(\d+)\s*(?:days?|day\b)', caseSensitive: false).firstMatch(lower);
        if (daysMatch != null) {
          extractedTime = daysMatch.group(1);
          extractedUnit = 'Days';
        }
      }
    }

    // 2. Extract Budget
    double? extractedBudget;
    // Look for budget numbers like "budget is 1500", "1500", "₹1500", "rs 2000", "under 3000", "2k budget", "3.5k"
    final budgetKMatch = RegExp(r'(?:budget|cost|price|under|approx|around)?\s*(?:is|of)?\s*(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d+)?)\s*k\b', caseSensitive: false).firstMatch(lower);
    if (budgetKMatch != null) {
      final val = double.tryParse(budgetKMatch.group(1) ?? '');
      if (val != null) {
        extractedBudget = val * 1000;
      }
    }

    if (extractedBudget == null) {
      final budgetMatch = RegExp(r'(?:budget|cost|price|under|approx|around|spending)?\s*(?:is|of)?\s*(?:₹|rs\.?|inr)\s*(\d+(?:,\d+)*(?:\.\d+)?)', caseSensitive: false).firstMatch(lower);
      if (budgetMatch != null) {
        final rawNum = (budgetMatch.group(1) ?? '').replaceAll(',', '');
        extractedBudget = double.tryParse(rawNum);
      }
    }

    if (extractedBudget == null) {
      // Fallback: look for "budget is 1500" or "budget 1500"
      final numAfterBudget = RegExp(r'budget\s*(?:is|of|around)?\s*(\d+)', caseSensitive: false).firstMatch(lower);
      if (numAfterBudget != null) {
        extractedBudget = double.tryParse(numAfterBudget.group(1) ?? '');
      }
    }

    // 3. Extract Group Type & Traveler Count
    String? extractedGroup;
    int? extractedTravelers;

    if (lower.contains('family') || lower.contains('kids') || lower.contains('children') || lower.contains('parents')) {
      extractedGroup = 'Family';
      extractedTravelers = 4;
    } else if (lower.contains('couple') || lower.contains('partner') || lower.contains('two of us') || lower.contains('2 of us') || lower.contains('girlfriend') || lower.contains('boyfriend') || lower.contains('wife') || lower.contains('husband')) {
      extractedGroup = 'Couple';
      extractedTravelers = 2;
    } else if (lower.contains('solo') || lower.contains('alone') || lower.contains('myself') || lower.contains('single') || lower.contains('1 person')) {
      extractedGroup = 'Solo';
      extractedTravelers = 1;
    } else if (lower.contains('friends') || lower.contains('buddies') || lower.contains('colleagues') || lower.contains('group') || lower.contains('gang')) {
      extractedGroup = 'Friends';
      extractedTravelers = 3;
    }

    final peopleMatch = RegExp(r'(\d+)\s*(?:people|persons|travelers|friends|adults)', caseSensitive: false).firstMatch(lower);
    if (peopleMatch != null) {
      final count = int.tryParse(peopleMatch.group(1) ?? '');
      if (count != null) {
        extractedTravelers = count;
        if (extractedGroup == null) {
          if (count == 1) {
            extractedGroup = 'Solo';
          } else if (count == 2) {
            extractedGroup = 'Couple';
          } else if (count <= 5) {
            extractedGroup = 'Friends';
          } else {
            extractedGroup = 'Family';
          }
        }
      }
    }

    // 4. Extract Location
    String? extractedCity;
    for (final city in knownCities) {
      if (lower.contains(city.toLowerCase())) {
        extractedCity = city;
        break;
      }
    }

    // 5. Extract Interests
    final List<String> matchedInterests = [];
    interestKeywords.forEach((category, keywords) {
      for (final kw in keywords) {
        if (lower.contains(kw)) {
          if (!matchedInterests.contains(category)) {
            matchedInterests.add(category);
          }
          break;
        }
      }
    });

    return AiPromptParsedResult(
      destination: extractedCity,
      time: extractedTime,
      timeUnit: extractedUnit,
      budget: extractedBudget,
      groupType: extractedGroup,
      travelerCount: extractedTravelers,
      interests: matchedInterests,
      rawPrompt: prompt,
    );
  }
}

/// Google-styled Voice & Prompt Input Bar for Itinerary Creation
class AiItineraryPromptBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<AiPromptParsedResult> onPromptApplied;
  final VoidCallback? onClear;

  const AiItineraryPromptBar({
    super.key,
    required this.controller,
    required this.onPromptApplied,
    this.onClear,
  });

  @override
  State<AiItineraryPromptBar> createState() => _AiItineraryPromptBarState();
}

class _AiItineraryPromptBarState extends State<AiItineraryPromptBar> with SingleTickerProviderStateMixin {
  late AnimationController _sparkleAnimController;
  AiPromptParsedResult? _lastParsedResult;
  bool _isAnalyzing = false;

  final List<String> _quickSuggestions = [
    '2 hr with family budget ₹1500 for street food',
    'Solo 3 hrs food & culture walk in Panvel under ₹800',
    'Half day couple nature & heritage trail budget ₹2500',
    'Full day adventure & hidden gems with friends ₹4000',
  ];

  @override
  void initState() {
    super.initState();
    _sparkleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sparkleAnimController.dispose();
    super.dispose();
  }

  void _triggerParse([String? overrideText]) {
    final text = overrideText ?? widget.controller.text;
    if (text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
    });

    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final result = AiPromptParser.parse(text);
      setState(() {
        _isAnalyzing = false;
        _lastParsedResult = result;
      });

      widget.onPromptApplied(result);
    });
  }

  void _openGoogleVoiceSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GoogleVoiceSearchModal(
        onSpokenPrompt: (spokenText) {
          widget.controller.text = spokenText;
          _triggerParse(spokenText);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Prompt Card with Google / Gemini styling
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0E8388),
                Color(0xFF2E7D32),
                Color(0xFFFF6B4A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: LocalLensColors.primaryTeal.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2), // Gradient border effect
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _sparkleAnimController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _sparkleAnimController.value * 0.2,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: LocalLensColors.primaryTealSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('✨', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Instant Itinerary Prompt',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: LocalLensColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: LocalLensColors.primaryTealSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'AUTO-FILLS FORM',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: LocalLensColors.primaryTealDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Main Textfield with Google Mic Corner Icon
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12, right: 6),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: LocalLensColors.primaryTeal,
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          maxLines: 2,
                          minLines: 1,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (val) => _triggerParse(val),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: LocalLensColors.textPrimary,
                            height: 1.3,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. "I have 2 hr with family my budget is ₹1500 and want street food"',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            isDense: true,
                          ),
                        ),
                      ),

                      // Clear Button (if text exists)
                      if (widget.controller.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                          visualDensity: VisualDensity.compact,
                          splashRadius: 18,
                          onPressed: () {
                            widget.controller.clear();
                            setState(() {
                              _lastParsedResult = null;
                            });
                            widget.onClear?.call();
                          },
                        ),

                      // Google Style Multi-Colored Mic Button
                      _buildGoogleMicButton(),

                      const SizedBox(width: 6),

                      // Apply AI Button
                      GestureDetector(
                        onTap: () => _triggerParse(),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [LocalLensColors.primaryTeal, Color(0xFF00875A)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: LocalLensColors.primaryTeal.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isAnalyzing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                                    SizedBox(width: 2),
                                    Text(
                                      'Apply',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Parsed Extraction Summary Chips (When AI has processed prompt)
                if (_lastParsedResult != null && _lastParsedResult!.hasAnyExtraction) ...[
                  const SizedBox(height: 10),
                  _buildParsedSummaryBadge(_lastParsedResult!),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Quick Suggestions Horizontal Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickSuggestions.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  widget.controller.text = suggestion;
                  _triggerParse(suggestion);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: LocalLensColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Google Voice Assistant Multi-Colored Microphone Icon Button
  Widget _buildGoogleMicButton() {
    return GestureDetector(
      onTap: _openGoogleVoiceSheet,
      child: Tooltip(
        message: 'Google Voice Input',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Google 4-color mic presentation
              CustomPaint(
                size: const Size(20, 20),
                painter: _GoogleMicPainter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParsedSummaryBadge(AiPromptParsedResult parsed) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
              SizedBox(width: 6),
              Text(
                'AI Extracted & Auto-Filled Parameters:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF166534),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (parsed.time != null)
                _buildTag('⏱️ ${parsed.time} ${parsed.timeUnit ?? "Hours"}'),
              if (parsed.groupType != null)
                _buildTag('👥 ${parsed.groupType} (${parsed.travelerCount ?? 2})'),
              if (parsed.budget != null)
                _buildTag('💰 ₹${parsed.budget!.toInt()}'),
              if (parsed.destination != null)
                _buildTag('📍 ${parsed.destination}'),
              ...parsed.interests.map((intName) => _buildTag('✨ $intName')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF15803D),
        ),
      ),
    );
  }
}

/// Custom Painter for Google-style 4-colored Mic
class _GoogleMicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Google Brand Colors
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    // Mic Head Upper (Blue)
    final bluePaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.15, w * 0.30, h * 0.22),
        const Radius.circular(4),
      ),
      bluePaint,
    );

    // Mic Body Middle (Red)
    final redPaint = Paint()
      ..color = red
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.35, h * 0.37, w * 0.30, h * 0.18),
      redPaint,
    );

    // Mic Base Ring (Green)
    final greenPaint = Paint()
      ..color = green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromLTWH(w * 0.22, h * 0.25, w * 0.56, h * 0.38);
    canvas.drawArc(arcRect, 0, 3.14159, false, greenPaint);

    // Mic Stand & Base (Yellow)
    final yellowPaint = Paint()
      ..color = yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.5, h * 0.63),
      Offset(w * 0.5, h * 0.82),
      yellowPaint,
    );
    canvas.drawLine(
      Offset(w * 0.32, h * 0.82),
      Offset(w * 0.68, h * 0.82),
      yellowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Google Voice Listening Assistant Bottom Sheet Modal
class _GoogleVoiceSearchModal extends StatefulWidget {
  final ValueChanged<String> onSpokenPrompt;

  const _GoogleVoiceSearchModal({required this.onSpokenPrompt});

  @override
  State<_GoogleVoiceSearchModal> createState() => _GoogleVoiceSearchModalState();
}

class _GoogleVoiceSearchModalState extends State<_GoogleVoiceSearchModal> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  String _recognizedTranscript = '';
  bool _isListening = true;

  final List<String> _sampleVoiceSuggestions = [
    'I have 2 hr with family my budget is ₹1500 and want street food',
    '3 hours food and heritage tour in Panvel for couple',
    'Solo half day nature and adventure under ₹1000',
    'Full day trip in Mumbai with 4 friends budget ₹3500',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Simulate natural speech detection start
    _startListeningSimulation();
  }

  void _startListeningSimulation() {
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _recognizedTranscript = 'I have 2 hr with family...';
        });
      }
    });

    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _recognizedTranscript = 'I have 2 hr with family my budget is ₹1500 and want street food';
          _isListening = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _confirmTranscript(String text) {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop();
    widget.onSpokenPrompt(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),

          // Google Gemini Voice Title
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Google Voice Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(width: 6),
              Text('🎙️', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isListening ? 'Listening... Speak your trip plan' : 'Voice recognized! Tap below or apply',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _isListening ? const Color(0xFF4285F4) : const Color(0xFF16A34A),
            ),
          ),

          const SizedBox(height: 28),

          // Animated Google Wave Pulsing Mic
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer animated expanding pulse rings
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 110 + (_pulseController.value * 30),
                    height: 110 + (_pulseController.value * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4285F4).withValues(alpha: (1 - _pulseController.value) * 0.25),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 90 + (_pulseController.value * 20),
                    height: 90 + (_pulseController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEA4335).withValues(alpha: (1 - _pulseController.value) * 0.2),
                    ),
                  );
                },
              ),

              // Center Circular Button
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(40, 40),
                    painter: _GoogleMicPainter(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Waveform bars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              return AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  final colors = [
                    const Color(0xFF4285F4),
                    const Color(0xFFEA4335),
                    const Color(0xFFFBBC05),
                    const Color(0xFF34A853),
                    const Color(0xFF4285F4),
                    const Color(0xFFEA4335),
                    const Color(0xFF34A853),
                  ];
                  final heightMultiplier = (index % 2 == 0)
                      ? _waveController.value
                      : (1.0 - _waveController.value);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 4,
                    height: 10 + (heightMultiplier * 20),
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 20),

          // Live Transcription Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              _recognizedTranscript.isEmpty
                  ? '"Speak something like: I have 2 hours with family my budget is ₹1500..."'
                  : '"$_recognizedTranscript"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _recognizedTranscript.isEmpty ? Colors.grey : LocalLensColors.textPrimary,
                fontStyle: _recognizedTranscript.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Tap Sample Voice Queries
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Or tap an example prompt:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),

          ..._sampleVoiceSuggestions.map((sug) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _confirmTranscript(sug),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic_none_rounded, size: 16, color: Color(0xFF4285F4)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sug,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              )),

          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _recognizedTranscript.isNotEmpty
                  ? () => _confirmTranscript(_recognizedTranscript)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Use Voice Input & Build Plan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
