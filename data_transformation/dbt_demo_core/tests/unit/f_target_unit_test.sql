version: 2

unit_tests:
  - name: f_target_incremental_test
    description: "Test for incremental load of f_target model"
    model: f_target
    overrides:
        macros:
            is_incremental: true
    given:
      - input: source('pro', 'f_source1')
        rows:
          - {id: 3, col1: "ghi", col2: 3344, processdate: 20250102}
      - input: source('pro', 'f_source2')
        rows:
          - {id: 2, col3: "uvw", processdate: 20250102}
          - {id: 3, col3: "stu", processdate: 20250102}
        - input: this
        rows:
          - {id: 1, col1: "abc", col2: 1122, col3: "xyz", co4: "f3-xyz", processdate: 20250101}
          - {id: 2, col1: "def", col2: 2233, col3: null, co4: null, processdate: 20250101}
    expect:
      rows:
        - {id: 1, col1: "abc", col2: 1122, col3: "xyz", co4: "f3-xyz", processdate: 20250101}
        - {id: 2, col1: "def", col2: 2233, col3: "uvw", co4: "f3 - uvw", processdate: 20250102}
        - {id: 3, col1: "ghi", col2: 3344, col3: "stu", co4: null, processdate: 20250102}