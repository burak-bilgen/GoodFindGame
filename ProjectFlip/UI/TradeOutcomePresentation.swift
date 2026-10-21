/// Uses settlement economics and earned inspection evidence; unknown condition stays unknown.
struct TradeOutcomePresentation: Equatable {
    let lessonKey: String
    let defects: [Defect]

    init(record: TradeRecord, item: ItemInstance?) {
        defects = item?.knownActiveDefects ?? []
        if record.netProfit > .zero { lessonKey = "result.lesson.win" }
        else if record.netProfit == .zero { lessonKey = "result.lesson.even" }
        else if record.soldFor >= record.acquiredFor {
            if record.inspectionCost == .zero { lessonKey = "result.lesson.repair" }
            else if record.repairCost == .zero { lessonKey = "result.lesson.inspection" }
            else { lessonKey = "result.lesson.costs" }
        }
        else { lessonKey = defects.isEmpty ? "result.lesson.price" : "result.lesson.fault" }
    }
}
