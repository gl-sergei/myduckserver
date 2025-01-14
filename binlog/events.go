// Copyright 2024-2025 ApeCloud, Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package binlog

type RowEventType int8

const (
	// IMPORTANT: The order of these values is important.
	// We translate UPDATE to DELETE + INSERT, so DELETE should come first.
	DeleteRowEvent RowEventType = iota
	UpdateRowEvent
	InsertRowEvent
)

func (e RowEventType) String() string {
	switch e {
	case DeleteRowEvent:
		return "DELETE"
	case UpdateRowEvent:
		return "UPDATE"
	case InsertRowEvent:
		return "INSERT"
	default:
		return "UNKNOWN"
	}
}
