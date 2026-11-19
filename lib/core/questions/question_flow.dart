import 'question.dart';

/// FlowForge soru ağacı tanımı.
abstract final class QuestionFlow {
  static final List<Question> all = List.unmodifiable(<Question>[
    Question(
      id: 'q_trigger',
      textKey: 'q_trigger',
      options: const [
        Option(
          labelKey: 'trigger.webhook',
          action: OptionAction.addNode,
          addsNodeKey: 'webhook',
          nextQuestionId: 'q_action',
        ),
        Option(
          labelKey: 'trigger.schedule',
          action: OptionAction.addNode,
          addsNodeKey: 'schedule',
          nextQuestionId: 'q_action',
        ),
        Option(
          labelKey: 'trigger.telegramTrigger',
          action: OptionAction.addNode,
          addsNodeKey: 'telegramTrigger',
          nextQuestionId: 'q_action',
        ),
      ],
    ),
    Question(
      id: 'q_action',
      textKey: 'q_action',
      options: const [
        Option(
          labelKey: 'action.httpRequest',
          action: OptionAction.addNode,
          addsNodeKey: 'httpRequest',
          nextQuestionId: 'q_condition',
        ),
        Option(
          labelKey: 'action.gmail',
          action: OptionAction.addNode,
          addsNodeKey: 'gmail',
          nextQuestionId: 'q_condition',
        ),
        Option(
          labelKey: 'action.googleSheets',
          action: OptionAction.addNode,
          addsNodeKey: 'googleSheets',
          nextQuestionId: 'q_condition',
        ),
        Option(
          labelKey: 'action.telegram',
          action: OptionAction.addNode,
          addsNodeKey: 'telegram',
          nextQuestionId: 'q_condition',
        ),
        Option(
          labelKey: 'action.none',
          action: OptionAction.skipToCondition,
          nextQuestionId: 'q_condition',
        ),
      ],
    ),
    Question(
      id: 'q_condition',
      textKey: 'q_condition',
      options: const [
        Option(
          labelKey: 'cond.none',
          action: OptionAction.goNext,
          nextQuestionId: 'q_output',
        ),
        Option(
          labelKey: 'cond.if',
          action: OptionAction.addNode,
          addsNodeKey: 'if',
          nextQuestionId: 'q_branch_true',
        ),
      ],
    ),
    Question(
      id: 'q_output',
      textKey: 'q_output',
      options: const [
        Option(
          labelKey: 'out.googleSheets',
          action: OptionAction.addNode,
          addsNodeKey: 'googleSheets',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'out.telegram',
          action: OptionAction.addNode,
          addsNodeKey: 'telegram',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'out.gmail',
          action: OptionAction.addNode,
          addsNodeKey: 'gmail',
          nextQuestionId: 'q_branch_continue',
        ),
      ],
    ),
    Question(
      id: 'q_branch_true',
      textKey: 'q_branch_true',
      options: const [
        Option(
          labelKey: 'out.googleSheets',
          action: OptionAction.addNode,
          addsNodeKey: 'googleSheets',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'out.telegram',
          action: OptionAction.addNode,
          addsNodeKey: 'telegram',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'out.gmail',
          action: OptionAction.addNode,
          addsNodeKey: 'gmail',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'branch.empty',
          action: OptionAction.endBranch,
          nextQuestionId: null,
        ),
      ],
    ),
    Question(
      id: 'q_branch_false',
      textKey: 'q_branch_false',
      options: const [
        Option(
          labelKey: 'out.googleSheets',
          action: OptionAction.addNode,
          addsNodeKey: 'googleSheets',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'out.telegram',
          action: OptionAction.addNode,
          addsNodeKey: 'telegram',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'out.gmail',
          action: OptionAction.addNode,
          addsNodeKey: 'gmail',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'branch.empty',
          action: OptionAction.endBranch,
          nextQuestionId: null,
        ),
      ],
    ),
    Question(
      id: 'q_branch_continue',
      textKey: 'q_branch_continue',
      options: const [
        Option(
          labelKey: 'branch.end',
          action: OptionAction.endBranch,
          nextQuestionId: null,
        ),
        Option(
          labelKey: 'action.httpRequest',
          action: OptionAction.addNode,
          addsNodeKey: 'httpRequest',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'action.gmail',
          action: OptionAction.addNode,
          addsNodeKey: 'gmail',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'action.googleSheets',
          action: OptionAction.addNode,
          addsNodeKey: 'googleSheets',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'action.telegram',
          action: OptionAction.addNode,
          addsNodeKey: 'telegram',
          nextQuestionId: 'q_branch_continue',
        ),
        Option(
          labelKey: 'cond.if',
          action: OptionAction.addNode,
          addsNodeKey: 'if',
          nextQuestionId: 'q_branch_true',
        ),
      ],
    ),
  ]);

  static final Map<String, Question> _byId = {
    for (final q in all) q.id: q,
  };

  /// [id] değerine sahip soruyu döndürür, yoksa `null`.
  static Question? byId(String id) => _byId[id];
}
