import Foundation
import libtidy

open class Libtidy {

    ///
    ///
    private let Success = yes

    ///
    ///
    private let utf8 = "utf8".cString(using: .utf8)


    public init() {

    }
    ///
    ///
    open func tidy(string input: String) -> String? {
        NSLog("IN \(input)")
        NSLog("IN \(input)")
        guard let document = tidyCreate() else {
            return nil
        }

        guard tidyOptSetBool(document, TidyXmlTags, yes) == Success else {
            return nil
        }

        guard tidyOptSetBool(document, TidyXmlOut, yes) == Success else {
            return nil
        }

        guard tidyOptSetBool(document, TidyForceOutput, yes) == Success else {
            return nil
        }

        guard tidyOptSetInt(document, TidyIndentContent, UInt(TidyAutoState.rawValue)) == Success else {
            return nil
        }

        guard tidySetInCharEncoding(document, utf8) == 0 else {
            return nil
        }

        guard tidySetOutCharEncoding(document, utf8) == 0 else {
            return nil
        }

        var buffer = TidyBuffer()
        tidyBufInit(UnsafeMutablePointer<TidyBuffer>(&buffer))

        guard tidySetErrorBuffer(document, UnsafeMutablePointer<TidyBuffer>(&buffer)) == 0 else {
            return nil
        }


        guard let inString = input.data(using: .utf8) else {
            return nil
        }


        let parseResult = inString.withUnsafeBytes { (inString: UnsafePointer<Int8>) -> Int32 in
            return tidyParseString(document, inString)
        }

        guard parseResult == 0 else {
            return nil
        }

        //    // Parse the data.
        //    theResultCode = tidyParseString(theTidyDocument, [inString UTF8String]);
        //    if (theResultCode < 0)
        //    {
        //        if (outError)
        //        {
        //            NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        //                                         [NSString stringWithUTF8String:(char *)theErrorBuffer.bp], NSLocalizedDescriptionKey,
        //                                         NULL];
        //            *outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:theResultCode userInfo:theUserInfo];
        //        }
        //        return(NULL);
        //    }

        guard tidyCleanAndRepair(document) == 0 else {
            return nil
        }

        guard tidyRunDiagnostics(document) == 0 else {
            return nil
        }

        var length = uint(0)
        tidySaveString(document, nil, UnsafeMutablePointer<uint>(&length) )


        guard let mutableData = NSMutableData(length: Int(length)) else {
            return nil
        }

        let data = mutableData.mutableBytes.bindMemory(to: Int8.self, capacity: Int(length))

        guard tidySaveString(document, data, UnsafeMutablePointer<uint>(&length)) == 0 else {
            return nil
        }

        guard let string = String(data: mutableData as Data, encoding: .utf8) else {
            return nil
        }

        //    if (theErrorBuffer.bp != NULL)
        //    {
        //        NSData *theErrorData = [NSData dataWithBytes:theErrorBuffer.bp length:theErrorBuffer.size];
        ////        *outDiagnostics = [[NSString alloc] initWithData:theErrorData encoding:NSUTF8StringEncoding];
        //    }

        tidyBufFree(UnsafeMutablePointer<TidyBuffer>(&buffer))

        tidyRelease(document)

        return string
    }
}




//- (NSString *)tidyString:(NSString *)inString encoding:(NSStringEncoding)inEncoding error:(NSError **)outError
//{
//    TidyDoc theTidyDocument = tidyCreate();
//
//    int theResultCode = 0;
//
//    // Set input format if input is XML (xhtml & html are the tidy 'default')
//    theResultCode = tidyOptSetBool(theTidyDocument, TidyXmlTags, YES);
//    NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
//
//    // Set output format
//    TidyOptionId theOutputValue = TidyXmlOut;
//    theResultCode = tidyOptSetBool(theTidyDocument, theOutputValue, YES);
//    NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
//
//    // Force output even if errors found
//    theResultCode = tidyOptSetBool(theTidyDocument, TidyForceOutput, YES);
//    NSAssert(theResultCode >= 0, @"tidyOptSetBool() should return 0");
//
//    // Pretty!
//    tidyOptSetInt(theTidyDocument, TidyIndentContent, TidyAutoState);
//
//    // Set encoding - same for input and output
//    theResultCode = tidySetInCharEncoding(theTidyDocument, "utf8");
//    NSAssert(theResultCode >= 0, @"tidySetInCharEncoding() should return 0");
//    theResultCode = tidySetOutCharEncoding(theTidyDocument, "utf8");
//    NSAssert(theResultCode >= 0, @"tidySetOutCharEncoding() should return 0");
//
//    // Create an error buffer
//    TidyBuffer theErrorBuffer;
//    tidyBufInit(&theErrorBuffer);
//    theResultCode = tidySetErrorBuffer(theTidyDocument, &theErrorBuffer);
//    NSAssert(theResultCode >= 0, @"tidySetErrorBuffer() should return 0");
//
//    // #############################################################################
//
//    // Parse the data.
//    theResultCode = tidyParseString(theTidyDocument, [inString UTF8String]);
//    if (theResultCode < 0)
//    {
//        if (outError)
//        {
//            NSDictionary *theUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//                                         [NSString stringWithUTF8String:(char *)theErrorBuffer.bp], NSLocalizedDescriptionKey,
//                                         NULL];
//            *outError = [NSError errorWithDomain:@"TODO_DOMAIN" code:theResultCode userInfo:theUserInfo];
//        }
//        return(NULL);
//    }
//
//    // Repair the data
//    theResultCode = tidyCleanAndRepair(theTidyDocument);
//    if (theResultCode < 0)
//    {
//        return(NULL);
//    }
//
//    //theResultCode = tidyRunDiagnostics(theTidyDocument);
//
//    //
//    uint theBufferLength = 0;
//
//    theResultCode = tidySaveString(theTidyDocument, NULL, &theBufferLength);
//
//    NSMutableData *theOutputBuffer = [NSMutableData dataWithLength:theBufferLength];
//
//    theResultCode = tidySaveString(theTidyDocument, [theOutputBuffer mutableBytes], &theBufferLength);
//
//    NSString *theString = [[NSString alloc] initWithData:theOutputBuffer encoding:NSUTF8StringEncoding];
//
//    //
//    if (theErrorBuffer.bp != NULL)
//    {
//        NSData *theErrorData = [NSData dataWithBytes:theErrorBuffer.bp length:theErrorBuffer.size];
////        *outDiagnostics = [[NSString alloc] initWithData:theErrorData encoding:NSUTF8StringEncoding];
//    }
//    tidyBufFree(&theErrorBuffer);
//
//    // #############################################################################
//
//    tidyRelease(theTidyDocument);
//
//    return(theString);
//}
