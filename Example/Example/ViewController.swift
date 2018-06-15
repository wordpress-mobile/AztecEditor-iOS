import UIKit

///
///
class ViewController: UITableViewController
{

    let cellIdentifier = "CellIdentifier"
    var sections: [DemoSection]!

    // MARK: LifeCycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        sections = [
            DemoSection(title: "Plain HTML Editor", rows: [
                DemoRow(title: "Standard Demo", action: { self.showEditorDemo(filename: "content") }),
                DemoRow(title: "Captions Demo", action: { self.showEditorDemo(filename: "captions") }),
                DemoRow(title: "Empty Demo", action: { self.showEditorDemo() })
                ]
            ),
            DemoSection(title: "WordPressEditor (Calypso & Gutenberg)", rows: [
                DemoRow(title: "Gutenberg Demo", action: { self.showEditorDemo(filename: "gutenberg", wordPressMode: true) }),
                DemoRow(title: "Empty Demo", action: { self.showEditorDemo(wordPressMode: true) })
                ]
            ),
        ]
    }

    // MARK: Actions

    func showEditorDemo(filename: String? = nil, wordPressMode: Bool = false) {
        let controller: EditorDemoController
            
        if let filename = filename {
            let sampleHTML = getSampleHTML(fromHTMLFileNamed: filename)

            controller = EditorDemoController(withSampleHTML: sampleHTML, wordPressMode: wordPressMode)
        } else {
            controller = EditorDemoController(wordPressMode: wordPressMode)
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
        return sections.count
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        cell.accessoryType = .disclosureIndicator

        let row = sections[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = row.title

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let textView = UITextView()
        
        textView.font = UIFont.boldSystemFont(ofSize: 14)
        textView.textAlignment = .center
        textView.isEditable = false
        textView.text = sections[section].title
        textView.backgroundColor = UIColor.lightGray
        
        return textView
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        sections[indexPath.section].rows[indexPath.row].action()
    }

}


typealias RowAction = () -> Void

struct DemoSection {
    var title: String
    var rows: [DemoRow]
}

struct DemoRow {
    var title: String
    var action: RowAction
}
