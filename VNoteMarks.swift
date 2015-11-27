//
//  VNoteMarks.swift
//  tablution
//
//  Created by Ian McCowan on 11/26/15.
//
//

import Foundation

enum MarkType {
    case Pre
    case Post
}

protocol NoteMark {}

enum PreNoteMark : Character, NoteMark {
    case None = "("
    case HammerOn = "h"
    case PullOff = "p"
    case Bend = "b"
    case Release = "r"
    case SlideUp = "/"
    case SlideDown = "\\"
}

enum PostNoteMark : Character, NoteMark {
    case None = ")"
    case Vibrato = "~"
}

func determineMarkType(markChar: Character) -> MarkType? {
    if PreNoteMark(rawValue: markChar) != nil {
        return .Pre
    }
    else if PostNoteMark(rawValue: markChar) != nil {
        return .Post
    }
    return nil
}