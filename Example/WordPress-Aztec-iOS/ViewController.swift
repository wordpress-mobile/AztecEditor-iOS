import UIKit

///
///
class ViewController: UITableViewController
{

    let cellIdentifier = "CellIdentifier"
    var rows:[DemoRow]!


    // MARK: LifeCycle Methods


    override func viewDidLoad() {
        super.viewDidLoad()

        rows = [
            DemoRow(title: "Editor Demo", action: { self.showEditorDemo() }),
            DemoRow(title: "Empty Editor Demo", action: { self.showEditorDemo(loadSampleHTML: false) }),
            DemoRow(title: "Cursor Callout Demo", action: { self.showCursorCalloutDemo() }),
            DemoRow(title: "Draggable Demo", action: { self.showDraggableDemo() }),
            DemoRow(title: "Formatter Demo", action: { self.showFormatterDemo() })
        ]
    }


    // MARK: Actions


    func showEditorDemo(loadSampleHTML loadSampleHTML: Bool = true) {
        let controller = EditorDemoController()
        controller.loadSampleHTML = loadSampleHTML
        navigationController?.pushViewController(controller, animated: true)
    }


    func showCursorCalloutDemo() {
        let controller = CursorCalloutDemoController.controller()
        navigationController?.pushViewController(controller, animated: true)
    }


    func showDraggableDemo() {
        let controller = DraggableDemoController.controller()
        navigationController?.pushViewController(controller, animated: true)
    }


    func showFormatterDemo() {
        let controller = FormattingDemoController.controller()
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: TableView Methods


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)!
        cell.accessoryType = .DisclosureIndicator

        let row = rows[indexPath.row]
        cell.textLabel?.text = row.title

        return cell
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        rows[indexPath.row].action()
    }

}


typealias RowAction = () -> Void


struct DemoRow {
    var title: String
    var action: RowAction
}
