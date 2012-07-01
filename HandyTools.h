//
//  HandyTools.h
//  tablution
//
//  Created by Ian Mccowan on 6/24/12.
//  Copyright (c) 2012 Nuance, Inc. All rights reserved.
//

#ifndef tablution_HandyTools_h
#define tablution_HandyTools_h

// From http://www.wilshipley.com/blog/2005/10/pimp-my-code-interlude-free-code.html

static inline BOOL IsEmpty(id thing) {
    return thing == nil
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

#endif
