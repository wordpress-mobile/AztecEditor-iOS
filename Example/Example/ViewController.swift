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
            DemoRow(title: "Editor Demo", action: { self.showEditorDemo(filename: "content") }),
            DemoRow(title: "Captions Demo", action: { self.showEditorDemo(filename: "captions") }),
            DemoRow(title: "Empty Editor Demo", action: { self.showEditorDemo() }),
        ]
    }

    // MARK: Actions

    func showEditorDemo(filename: String? = nil) {
        let controller: EditorDemoController
            
        if let filename = filename {
            let sampleHTML = getSampleHTML(fromHTMLFileNamed: filename)

            controller = EditorDemoController(withSampleHTML: sampleHTML)
        } else {
            controller = EditorDemoController()
        }
        
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: Sample HTML
    
    func getSampleHTML(fromHTMLFileNamed fileName: String) -> String {
        let htmlFilePath = Bundle.main.path(forResource: fileName, ofType: "html")!
        let fileContents: String
        
        do {
            fileContents = try String(contentsOfFile: htmlFilePath)
        } catch {
            fatalError("Could not load the sample HTML.  Check the file exists in the target and that it has the correct name.")
        }
        
        return fileContents
    }
    
    // MARK: TableView Methods


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        cell.accessoryType = .disclosureIndicator

        let row = rows[indexPath.row]
        cell.textLabel?.text = row.title

        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        rows[indexPath.row].action()
    }

}


typealias RowAction = () -> Void


struct DemoRow {
    var title: String
    var action: RowAction
}
