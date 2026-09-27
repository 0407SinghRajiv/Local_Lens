import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/locallens_design_system.dart';
import '../models/itinerary_model.dart';
import '../providers/itinerary_provider.dart';
import '../services/groq_itinerary_service.dart';

/// Chat message model for optimizer conversation
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final GroqOptimizationResult? optimizationResult;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.optimizationResult,
  });
}

/// Bottom Sheet Chatbot for Interactive Itinerary Optimization via Groq AI
class ItineraryOptimizerChatSheet extends ConsumerStatefulWidget {
  final Itinerary currentItinerary;

  const ItineraryOptimizerChatSheet({
    super.key,
    required this.currentItinerary,
  });

  /// Static helper to display the sheet
  static Future<void> show(BuildContext context, Itinerary itinerary) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ItineraryOptimizerChatSheet(currentItinerary: itinerary),
    );
  }

  @override
  ConsumerState<ItineraryOptimizerChatSheet> createState() => _ItineraryOptimizerChatSheetState();
}

class _ItineraryOptimizerChatSheetState extends ConsumerState<ItineraryOptimizerChatSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _isProcessing = false;
  bool _isRegenerating = false;

  final List<String> _quickSuggestions = [
    '🏛️ Tell me about my stops & history',
    '🍛 What local food should I try nearby?',
    '🏖️ Change food with beaches so generate it',
    '⏱️ Optimize route sequence only',
    '🛕 Any hidden cultural gems nearby?',
    '💰 Reduce budget by ₹1000',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message from LocalLens Saathi
    final destination = widget.currentItinerary.destination.isNotEmpty
        ? widget.currentItinerary.destination
        : 'your trip';
    _messages.add(
      _ChatMessage(
        text: 'Namaste! 🙏 I am **LocalLens Saathi** (लोकललेंस साथी), your personal local travel guide & itinerary companion.\n\n'
            'I can:\n'
            '• 🏛️ Share stories, history, timings & details for any stop in $destination\n'
            '• 🍛 Recommend authentic local street food & must-try delicacies\n'
            '• ⚡ Customize your itinerary (e.g. "*change food with beaches so generate it*")\n'
            '• ⏱️ Optimize your route for the fastest travel sequence\n\n'
            'How can I guide you today, dost?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? overrideText]) async {
    final text = (overrideText ?? _inputController.text).trim();
    if (text.isEmpty || _isProcessing || _isRegenerating) return;

    if (overrideText == null) {
      _inputController.clear();
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isProcessing = true;
    });
    _scrollToBottom();

    final state = ref.read(itineraryProvider);
    final placeNames = widget.currentItinerary.items.map((i) => i.name).toList();
    final placeDetails = widget.currentItinerary.items.map((i) => {
      'name': i.name,
      'category': i.category,
      'location': i.location,
      'description': i.description,
      'price_inr': i.price,
      'time_window': i.timeWindow,
    }).toList();

    // Prepare chat history for context
    final history = <Map<String, String>>[];
    for (final m in _messages.take(_messages.length - 1)) {
      history.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      });
    }

    try {
      final result = await GroqItineraryService.analyzeRequest(
        prompt: text,
        destination: widget.currentItinerary.destination,
        currentInterests: state.interests,
        budget: state.totalBudgetInr,
        durationHours: state.durationHours,
        currentPlaceNames: placeNames,
        chatHistory: history,
        placesDetails: placeDetails,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            text: result.reply,
            isUser: false,
            timestamp: DateTime.now(),
            optimizationResult: result,
          ),
        );
        _isProcessing = false;
      });
      _scrollToBottom();

      // If user explicitly asks "generate it" / "so generate it" or prompt dictates direct generation
      final lowerText = text.toLowerCase();
      final hasGenerateDirective = lowerText.contains('generate it') ||
          lowerText.contains('so generate it') ||
          lowerText.contains('make it now') ||
          lowerText.contains('create it');

      if (result.isRouteReorderOnly) {
        // Fast route optimization
        await _executeRouteOptimization();
      } else if (!result.isInfoQuery && result.shouldRegenerate && hasGenerateDirective) {
        // Delay slightly for natural conversational feel then trigger regeneration
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) {
          await _executeRegeneration(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: 'I could not process the request directly, but I can still update your trip preferences!',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isProcessing = false;
        });
        _scrollToBottom();
      }
    }
  }

  /// Pure route sequence TSP optimization
  Future<void> _executeRouteOptimization() async {
    final notifier = ref.read(itineraryProvider.notifier);
    setState(() => _isRegenerating = true);

    try {
      final optimized = await notifier.optimizeCurrentItinerary();
      if (mounted) {
        Navigator.of(context).pop();
        if (optimized != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Itinerary route optimized for fastest travel time & sequence!',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: LocalLensColors.primaryTeal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to optimize route: $e'),
            backgroundColor: LocalLensColors.errorRed,
          ),
        );
      }
    }
  }

  /// Applies interest/preference changes, fetches fresh recommendations, and routes to Swipe screen
  Future<void> _executeRegeneration(GroqOptimizationResult result) async {
    if (_isRegenerating) return;

    setState(() => _isRegenerating = true);

    final notifier = ref.read(itineraryProvider.notifier);

    // 1. Update state with modified interests, budget, duration, and reset previous selection
    notifier.applyOptimizationChanges(
      removeInterests: result.removeInterests,
      addInterests: result.addInterests,
      customNotes: result.customNotes,
      budget: result.updatedBudget,
      durationHours: result.updatedDurationHours,
    );

    try {
      // 2. Fetch fresh recommendation candidate pool reflecting changes (e.g. Beaches instead of Food)
      final recs = await notifier.fetchRecommendations();

      if (!mounted) return;

      // 3. Dismiss bottom sheet
      Navigator.of(context).pop();

      // 4. Navigate to Swipe screen so traveler can swipe the newly recommended places
      context.push(AppRoutes.recommendationSwipe);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.swipe_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fresh recommendations ready (${recs.length} places)! Swipe to build your updated itinerary.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: LocalLensColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isRegenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load new recommendations: $e'),
            backgroundColor: LocalLensColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88,
      decoration: const BoxDecoration(
        color: LocalLensColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              // Top Drag Handle & Header
              _buildHeader(context),

              // Chat Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length + (_isProcessing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isProcessing) {
                      return _buildThinkingBubble();
                    }
                    final msg = _messages[index];
                    return _buildMessageItem(msg);
                  },
                ),
              ),

              // Quick suggestion chips
              if (!_isProcessing && !_isRegenerating) _buildQuickChips(),

              // Input bar
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(bottom: BorderSide(color: LocalLensColors.border, width: 1)),
      ),
      child: Column(
        children: [
          // Drag pill
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: LocalLensColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LocalLensColors.primaryTealSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: LocalLensColors.primaryTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'LocalLens Saathi',
                          style: LocalLensTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: LocalLensColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9933).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '🇮🇳 SAATHI AI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your Indian Travel Guide & Companion • Ask place info & customize trip',
                      style: LocalLensTypography.caption.copyWith(
                        color: LocalLensColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: LocalLensColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(_ChatMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: LocalLensColors.deepInk,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: LocalLensTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant message
    final opt = msg.optimizationResult;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: const BoxDecoration(
                  color: LocalLensColors.primaryTealSoft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: LocalLensColors.primaryTeal,
                    size: 16,
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: LocalLensColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: LocalLensTypography.bodyMedium.copyWith(
                      color: LocalLensColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // If optimization changes detected, display interactive summary card
          if (opt != null && opt.hasInterestChanges) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: _buildActionCard(opt),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(GroqOptimizationResult opt) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LocalLensColors.primaryTeal.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: LocalLensColors.primaryTeal.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.change_circle_rounded, color: LocalLensColors.primaryTeal, size: 18),
              const SizedBox(width: 6),
              Text(
                'Detected Optimization Updates',
                style: LocalLensTypography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: LocalLensColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Removed items
          if (opt.removeInterests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Text('❌ Remove: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LocalLensColors.errorRed)),
                  Wrap(
                    spacing: 6,
                    children: opt.removeInterests.map((r) => Chip(
                      label: Text(r, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: LocalLensColors.errorRedSoft,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
              ),
            ),

          // Added items
          if (opt.addInterests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Text('✨ Add: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: LocalLensColors.successGreen)),
                  Wrap(
                    spacing: 6,
                    children: opt.addInterests.map((a) => Chip(
                      label: Text(a, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: LocalLensColors.successGreenSoft,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
              ),
            ),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRegenerating ? null : () => _executeRegeneration(opt),
              icon: _isRegenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
              label: Text(
                _isRegenerating ? 'Fetching New Recommendations...' : 'Regenerate Recommendations & Swipe',
                style: LocalLensTypography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: LocalLensColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: LocalLensColors.primaryTealSoft,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded, color: LocalLensColors.primaryTeal, size: 16),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LocalLensColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: LocalLensColors.primaryTeal),
                ),
                const SizedBox(width: 10),
                Text(
                  'LocalLens Saathi is thinking...',
                  style: LocalLensTypography.caption.copyWith(
                    color: LocalLensColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickSuggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final text = _quickSuggestions[index];
          return ActionChip(
            label: Text(
              text,
              style: LocalLensTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: LocalLensColors.textPrimary,
              ),
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: LocalLensColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _handleSendMessage(text),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: LocalLensColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: LocalLensColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: LocalLensColors.border),
              ),
              child: TextField(
                controller: _inputController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
                enabled: !_isProcessing && !_isRegenerating,
                style: LocalLensTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Ask Saathi: e.g. "tell me about Belapur Fort" or "swap food with beaches"...',
                  hintStyle: LocalLensTypography.caption.copyWith(
                    color: LocalLensColors.textMuted,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: LocalLensColors.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isProcessing || _isRegenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              onPressed: (_isProcessing || _isRegenerating) ? null : () => _handleSendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
