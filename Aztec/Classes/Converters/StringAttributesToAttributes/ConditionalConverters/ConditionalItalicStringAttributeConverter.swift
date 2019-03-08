import Foundation


class ConditionalItalicStringAttributeConverter: ConditionalStringAttributeConverter {
    
    init() {
        let citeBranch: Branch = {
            let predicate: ConditionalStringAttributeConverter.Predicate = { attributes -> Bool in
                
                return ConditionalItalicStringAttributeConverter.hasCiteRepresentation(attributes)
            }
            
            let converter = CiteStringAttributeConverter()
            
            return ConditionalStringAttributeConverter.Branch(predicate: predicate, converter: converter)
        }()
        
        let italicBranch: Branch = {
            let predicate: ConditionalStringAttributeConverter.Predicate = { attributes -> Bool in
                return true
            }
            
            let converter = ItalicStringAttributeConverter()
            
            return ConditionalStringAttributeConverter.Branch(predicate: predicate, converter: converter)
        }()
        
        super.init(branches: [citeBranch, italicBranch])
    }
    
    // MARK: - Predicate logic
    
    private static func hasCiteRepresentation(_ attributes: [NSAttributedString.Key: Any]) -> Bool {
        return attributes[NSAttributedString.Key.citeHtmlRepresentation] as? HTMLRepresentation != nil
    }
}
