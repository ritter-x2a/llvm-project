"""
Test lldb-dap setBreakpoints request
"""


import dap_server
from lldbsuite.test.decorators import *
from lldbsuite.test.lldbtest import *
from lldbsuite.test import lldbutil
import lldbdap_testcase


@skip("Temporarily disable the breakpoint tests")
class TestDAP_setFunctionBreakpoints(lldbdap_testcase.DAPTestCaseBase):
    @skipIfWindows
    def test_set_and_clear(self):
        """Tests setting and clearing function breakpoints.
        This packet is a bit tricky on the debug adapter side since there
        is no "clearFunction Breakpoints" packet. Function breakpoints
        are set by sending a "setFunctionBreakpoints" packet with zero or
        more function names. If function breakpoints have been set before,
        any existing breakpoints must remain set, and any new breakpoints
        must be created, and any breakpoints that were in previous requests
        and are not in the current request must be removed. This function
        tests this setting and clearing and makes sure things happen
        correctly. It doesn't test hitting breakpoints and the functionality
        of each breakpoint, like 'conditions' and 'hitCondition' settings.
        """
        # Visual Studio Code Debug Adapters have no way to specify the file
        # without launching or attaching to a process, so we must start a
        # process in order to be able to set breakpoints.
        program = self.getBuildArtifact("a.out")
        self.build_and_launch(program)
        bp_id_12 = None
        functions = ["twelve"]
        # Set a function breakpoint at 'twelve'
        response = self.dap_server.request_setFunctionBreakpoints(functions)
        if response:
            breakpoints = response["body"]["breakpoints"]
            self.assertEqual(
                len(breakpoints),
                len(functions),
                "expect %u source breakpoints" % (len(functions)),
            )
            for breakpoint in breakpoints:
                bp_id_12 = breakpoint["id"]
                self.assertTrue(breakpoint["verified"], "expect breakpoint verified")

        # Add an extra name and make sure we have two breakpoints after this
        functions.append("thirteen")
        response = self.dap_server.request_setFunctionBreakpoints(functions)
        if response:
            breakpoints = response["body"]["breakpoints"]
            self.assertEqual(
                len(breakpoints),
                len(functions),
                "expect %u source breakpoints" % (len(functions)),
            )
            for breakpoint in breakpoints:
                self.assertTrue(breakpoint["verified"], "expect breakpoint verified")

        # There is no breakpoint delete packet, clients just send another
        # setFunctionBreakpoints packet with the different function names.
        functions.remove("thirteen")
        response = self.dap_server.request_setFunctionBreakpoints(functions)
        if response:
            breakpoints = response["body"]["breakpoints"]
            self.assertEqual(
                len(breakpoints),
                len(functions),
                "expect %u source breakpoints" % (len(functions)),
            )
            for breakpoint in breakpoints:
                bp_id = breakpoint["id"]
                self.assertEqual(
                    bp_id, bp_id_12, 'verify "twelve" breakpoint ID is same'
                )
                self.assertTrue(
                    breakpoint["verified"], "expect breakpoint still verified"
                )

        # Now get the full list of breakpoints set in the target and verify
        # we have only 1 breakpoints set. The response above could have told
        # us about 1 breakpoints, but we want to make sure we don't have the
        # second one still set in the target
        response = self.dap_server.request_testGetTargetBreakpoints()
        if response:
            breakpoints = response["body"]["breakpoints"]
            self.assertEqual(
                len(breakpoints),
                len(functions),
                "expect %u source breakpoints" % (len(functions)),
            )
            for breakpoint in breakpoints:
                bp_id = breakpoint["id"]
                self.assertEqual(
                    bp_id, bp_id_12, 'verify "twelve" breakpoint ID is same'
                )
                self.assertTrue(
                    breakpoint["verified"], "expect breakpoint still verified"
                )

        # Now clear all breakpoints for the source file by passing down an
        # empty lines array
        functions = []
        response = self.dap_server.request_setFunctionBreakpoints(functions)
        if response:
            breakpoints = response["body"]["breakpoints"]
            self.assertEqual(
                len(breakpoints),
                len(functions),
                "expect %u source breakpoints" % (len(functions)),
            )

        # Verify with the target that all breakpoints have been cleared
        response = self.dap_server.request_testGetTargetBreakpoints()
        if response:
            breakpoints = response["body"]["breakpoints"]
            self.assertEqual(
                len(breakpoints),
                len(functions),
                "expect %u source breakpoints" % (len(functions)),
            )

    @skipIfWindows
    def test_functionality(self):
        """Tests hitting breakpoints and the functionality of a single
        breakpoint, like 'conditions' and 'hitCondition' settings."""

        program = self.getBuildArtifact("a.out")
        self.build_and_launch(program)
        # Set a breakpoint on "twelve" with no condition and no hitCondition
        functions = ["twelve"]
        breakpoint_ids = self.set_function_breakpoints(functions)

        self.assertEqual(len(breakpoint_ids), len(functions), "expect one breakpoint")

        # Verify we hit the breakpoint we just set
        self.continue_to_breakpoints(breakpoint_ids)

        # Make sure i is zero at first breakpoint
        i = int(self.dap_server.get_local_variable_value("i"))
        self.assertEqual(i, 0, "i != 0 after hitting breakpoint")

        # Update the condition on our breakpoint
        new_breakpoint_ids = self.set_function_breakpoints(functions, condition="i==4")
        self.assertEqual(
            breakpoint_ids,
            new_breakpoint_ids,
            "existing breakpoint should have its condition " "updated",
        )

        self.continue_to_breakpoints(breakpoint_ids)
        i = int(self.dap_server.get_local_variable_value("i"))
        self.assertEqual(i, 4, "i != 4 showing conditional works")
        new_breakpoint_ids = self.set_function_breakpoints(functions, hitCondition="2")

        self.assertEqual(
            breakpoint_ids,
            new_breakpoint_ids,
            "existing breakpoint should have its condition " "updated",
        )

        # Continue with a hitCondition of 2 and expect it to skip 1 value
        self.continue_to_breakpoints(breakpoint_ids)
        i = int(self.dap_server.get_local_variable_value("i"))
        self.assertEqual(i, 6, "i != 6 showing hitCondition works")

        # continue after hitting our hitCondition and make sure it only goes
        # up by 1
        self.continue_to_breakpoints(breakpoint_ids)
        i = int(self.dap_server.get_local_variable_value("i"))
        self.assertEqual(i, 7, "i != 7 showing post hitCondition hits every time")
