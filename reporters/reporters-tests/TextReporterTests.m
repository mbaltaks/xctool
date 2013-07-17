//
// Copyright 2013 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <SenTestingKit/SenTestingKit.h>

#import "FakeFileHandle.h"
#import "ReporterEvents.h"
#import "Reporter+Testing.h"
#import "TextReporter.h"

@interface TextReporterTests : SenTestCase
@end

@implementation TextReporterTests

/**
 Just verify the plumbing works and our text reporters don't crash when getting
 fed events.  This is a really lame test - over time, we should add cases to
 actually verify output.
 */
- (void)testReporterDoesntCrash
{
  void (^pumpReporter)(Class, NSString *) = ^(Class cls, NSString *path) {
    NSLog(@"pumpReporter(%@, %@) ...", cls, path);

    // Pump the events to make sure all the plumbing works and we don't crash.
    [cls outputDataWithEventsFromFile:path];
  };

  pumpReporter([PlainTextReporter class], TEST_DATA @"JSONStreamReporter-build-good.txt");
  pumpReporter([PlainTextReporter class], TEST_DATA @"JSONStreamReporter-build-bad.txt");
  pumpReporter([PlainTextReporter class], TEST_DATA @"JSONStreamReporter-runtests.txt");

  pumpReporter([PrettyTextReporter class], TEST_DATA @"JSONStreamReporter-build-good.txt");
  pumpReporter([PrettyTextReporter class], TEST_DATA @"JSONStreamReporter-build-bad.txt");
  pumpReporter([PrettyTextReporter class], TEST_DATA @"JSONStreamReporter-runtests.txt");
}

- (void)testStatusMessageShowsOneLineWithNoDuration
{
  NSArray *events = @[
                      @{@"event": kReporter_Events_BeginStatus,
                        kReporter_BeginStatus_MessageKey: @"Some message...",
                        kReporter_BeginStatus_TimestampKey: @(1),
                        kReporter_BeginStatus_LevelKey: @"Info",
                        },
                      @{@"event": kReporter_Events_EndStatus,
                        kReporter_EndStatus_MessageKey: @"Some message...",
                        kReporter_EndStatus_TimestampKey: @(1),
                        kReporter_EndStatus_LevelKey: @"Info",
                        },
                      ];

  assertThat([PrettyTextReporter outputStringWithEvents:events],
             equalTo(// the first line, from beginStatusMessage:
                     @"\r[Info] Some message..."
                     // the second line, from endStatusMessage:
                     @"\r[Info] Some message...\n"
                     // the trailing newline from -[Reporter close]
                     @"\n"));
}

- (void)testStatusMessageWithBeginAndEndIncludesDuration
{
  NSArray *events = @[
                      // begin at T+0 seconds.
                      @{@"event": kReporter_Events_BeginStatus,
                        kReporter_BeginStatus_MessageKey: @"Some message...",
                        kReporter_BeginStatus_TimestampKey: @(1),
                        kReporter_BeginStatus_LevelKey: @"Info",
                        },
                      // begin at T+1 seconds.
                      @{@"event": kReporter_Events_EndStatus,
                        kReporter_EndStatus_MessageKey: @"Some message.",
                        kReporter_EndStatus_TimestampKey: @(2),
                        kReporter_EndStatus_LevelKey: @"Info",
                        },
                      ];

  assertThat([PrettyTextReporter outputStringWithEvents:events],
             equalTo(// the first line, from beginStatusMessage:
                     @"\r[Info] Some message..."
                     // the second line, from endStatusMessage:
                     @"\r[Info] Some message. (1000 ms)\n"
                     // the trailing newline from -[Reporter close]
                     @"\n"));
}

@end
